import math

import pandas as pd
import requests

from esgf_search import facets

KEYWORDS = (
    'facets',
    'offset',
    'limit',
    'fields',
    'format',
    'type',
    'replica',
    'latest',
    'distrib',
    'shards',
    'bbox',
    'start',
    'end',
    'from',
    'to',
)


def clean_results(x):
    try:
        if isinstance(x[0], list) and len(x[0]) == 1:
            return [y[0] for y in x]
    except TypeError:
        pass

    return x


class SearchError(Exception):
    pass


class UnknownFacetError(SearchError):
    def __init__(self, key, facets):
        fmt = 'Unknown facet {!r}, possible values {!s}'

        err_msg = fmt.format(key, ', '.join(facets.keys()))

        super(UnknownFacetError, self).__init__(err_msg)


class UnknownFacetValueError(SearchError):
    def __init__(self, value, facet, possible_values):
        fmt = 'Unknown value {!r} for facet {!s}, possible values {!s}'

        err_msg = fmt.format(value, facet, ', '.join(possible_values))

        super(UnknownFacetValueError, self).__init__(err_msg)


# https://earthsystemcog.org/projects/cog/esgf_search_restful_api
class ESGF(object):
    def __init__(self, base_url=None, search_params=None, **keywords):
        self.base_url = base_url or 'https://esgf-node.llnl.gov/esg-search/search'
        self.offset = 0
        self.default_params = {
            'distrib': keywords.get('distrib', True),
            'query': keywords.get('query', '*'),
            'format': keywords.get('format', 'application/solr+json'),
            'type': keywords.get('type', 'Dataset'),
            'limit': keywords.get('limit', 10),
        }
        self.search_params = search_params or {}
        self._facets = None

    @property
    def pages(self):
        return math.ceil(self.num_found / self.default_params['limit'])

    @property
    def facets(self):
        if self._facets is None:
            project = self.search_params.get('project', 'all')

            self._facets = facets.get_facets(preset=project.lower())

        return self._facets.keys()

    def facet_values(self, name):
        if name not in self.facets:
            data = facets.get_facets(facets=[name], **self.search_params)

            return data

        return self._facets[name]

    def parse_results(self, result):
        self.num_found = result['response']['numFound']

        return result['response']['docs']

    def _search(self, kwargs):
        raw = kwargs.get('raw', False)

        try:
            response = requests.get(self.base_url, params=kwargs)
        except Exception as e:
            raise SearchError('Server error {!s}'.format(e))

        if response.ok:
            data = self.parse_results(response.json())
        else:
            raise SearchError('Server returned {!r} status code {!r}'.format(response.status_code, response.text))

        df = pd.DataFrame.from_dict(data)

        if not raw:
            df = df.apply(clean_results)

        new_url = df['url'].apply(pd.Series)

        new_url = new_url.rename(columns=lambda x: new_url[x][0].split('|')[-1])

        df = pd.concat([df[:], new_url[:]], axis=1)

        del df['url']

        return df

    def search(self, **kwargs):
        self.default_params['offset'] = 0

        self.search_params.update(kwargs)

        params = self.default_params.copy()
        params.update(self.search_params)

        return self._search(params)

    def next(self):
        if self.page + 1 > self.pages:
            raise Exception('Your past the last page')

        self.page += 1

        self.default_params['offset'] = self.page*self.items_per_page

        params = self.default_params.copy()
        params.update(self.search_params)

        return self._search(params)

    def previous(self):
        if self.page - 1 < 0:
            raise Exception('Your past the first page')

        self.page -= 1

        self.default_params['offset'] = self.page*self.items_per_page

        params = self.default_params.copy()
        params.update(self.search_params)

        return self._search(params)


class CMIP5(ESGF):
    def __init__(self, **kwargs):
        super(CMIP5, self).__init__(**kwargs)

        self.search_params.update(project='CMIP5')


class CMIP6(ESGF):
    def __init__(self, **kwargs):
        super(CMIP6, self).__init__(**kwargs)

        self.search_params.update(project='CMIP6')
