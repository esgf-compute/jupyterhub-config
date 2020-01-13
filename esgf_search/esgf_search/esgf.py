import math

import pandas as pd
import requests

from esgf_search import facets

SEARCH_PARAMS = (
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


class ESGF(object):
    def __init__(self, preset=None, base_url=None, items_per_page=None):
        self.base_url = base_url or 'https://esgf-node.llnl.gov/esg-search/search'
        self.numFound = 0
        self.page = 0
        self.items_per_page = items_per_page or 10
        self.default_params = {
            'format': 'application/solr+json',
            'type': 'File',
        }
        self.user_params = {}

        if preset is None:
            preset = 'all'

        self.facets = facets.get_facets(preset)

    @property
    def pages(self):
        return math.ceil(self.numFound / self.items_per_page)

    def parse_results(self, result):
        self.numFound = result['response']['numFound']

        return result['response']['docs']

    def _search(self, kwargs):
        clean = kwargs.pop('clean', True)

        expand_urls = kwargs.pop('expand_urls', False)

        kwargs['limit'] = self.items_per_page

        try:
            response = requests.get(self.base_url, params=kwargs)
        except Exception as e:
            raise SearchError('Server error {!s}'.format(e))

        if response.ok:
            data = self.parse_results(response.json())
        else:
            raise SearchError('Server returned {!r} status code {!r}'.format(response.status_code, response.text))

        df = pd.DataFrame.from_dict(data)

        if clean:
            df = df.apply(clean_results)

        if expand_urls:
            new_url = df['url'].apply(pd.Series)

            new_url = new_url.rename(columns=lambda x: new_url[x][0].split('|')[-1])

            df = pd.concat([df[:], new_url[:]], axis=1)

            del df['url']

        return df

    def search(self, **kwargs):
        self.user_params = kwargs.copy()
        self.user_params.update(self.default_params)

        if 'offset' not in self.user_params:
            self.user_params['offset'] = 0

        for x, y in self.user_params.items():
            if x in SEARCH_PARAMS:
                continue

            if x in self.facets:
                # Handle search for multiple values e.g. variable='pr,prw'
                for item in y.split(','):
                    if item not in self.facets[x]:
                        raise UnknownFacetValueError(item, x, self.facets[x])
            else:
                raise UnknownFacetError(x, self.facets)

        return self._search(self.user_params)

    def next(self):
        if self.page + 1 > self.pages:
            raise Exception('Your past the last page')

        self.page += 1

        self.user_params['offset'] = self.page*self.items_per_page

        return self._search(self.user_params)

    def previous(self):
        if self.page - 1 < 0:
            raise Exception('Your past the first page')

        self.page -= 1

        self.user_params['offset'] = self.page*self.items_per_page

        return self._search(self.user_params)


class CMIP5(ESGF):
    def __init__(self, **kwargs):
        super(CMIP5, self).__init__('cmip5', **kwargs)


class CMIP6(ESGF):
    def __init__(self, **kwargs):
        super(CMIP6, self).__init__('cmip6', **kwargs)
