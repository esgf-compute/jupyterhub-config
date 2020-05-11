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


def column_reduce(x):
    """ Flatten column values.
    """
    try:
        if isinstance(x[0], list) and len(x[0]) == 1:
            return [y[0] for y in x]
    except TypeError:
        pass

    return x


class SearchError(Exception):
    pass

class InvalidKeywordError(SearchError):
    """ Invalid keyword error.
    """
    def __init__(self, key):
        super().__init__('{!r} is an invalid keyword'.format(key))

class UnknownFacetError(SearchError):
    """ Unknown facet error.
    """
    def __init__(self, key, facets):
        fmt = 'Unknown facet {!r}, possible values {!s}'

        err_msg = fmt.format(key, ', '.join(facets.keys()))

        super(UnknownFacetError, self).__init__(err_msg)


class UnknownFacetValueError(SearchError):
    """ Unknown facet value error.
    """
    def __init__(self, value, facet, possible_values):
        fmt = 'Unknown value {!r} for facet {!s}, possible values {!s}'

        err_msg = fmt.format(value, facet, ', '.join(possible_values))

        super(UnknownFacetValueError, self).__init__(err_msg)


# https://earthsystemcog.org/projects/cog/esgf_search_restful_api
class ESGF(object):
    def __init__(self, base_url=None, facet_query=None, **keywords):
        """ ESGF search interface.

        This provides a simple interface for ESGF search.

        Default keywords and facet query can be set in the constructor. See documentation link below for full list
        of keywords and facets.

        The `format` keyword is disallowed.

        >>> esgf = ESGF(facet_query={'project': 'CMIP5'}, type='File')

        >>> result = esgf.search(variable='pr')

        See https://earthsystemcog.org/projects/cog/esgf_search_restful_api for full documentation of search API.

        Args:
            base_url (str): URL for the ESGF search endpoint (default: 'https://esgf-ndoe.llnl.gov/esg-search/search')
            search_params (dict, optional): Dictionary of default search parameters, see description above.
            **kwargs: Keyword arguments to be passed in search query.
        """
        self.base_url = base_url or 'https://esgf-node.llnl.gov/esg-search/search'
        self.offset = 0
        self.default_keywords = {
            'distrib': True,
            'format': 'application/solr+json',
            'type': 'Dataset',
            'limit': 10
        }

        # Remove format if present, this must remain the default value.
        keywords.pop('format', None)

        # Validate keywords
        for x, y in keywords.items():
            if x not in KEYWORDS:
                raise InvalidKeywordError(x)

            self.default_keywords[x] = y

        self.default_facets = facet_query or {}

        if 'query' not in self.default_facets:
            self.default_facets['query'] = '*'

        self.params = {}
        self.page = 1
        self._facets = None

    @property
    def pages(self):
        """ Returns the number of pages.

        >>> esgf = ESGF()

        >>> result = esgf.search(project='CMIP5', variable='pr')

        >>> print(esgf.pages) # doctest:+SKIP

        """
        return math.ceil(self.num_found / self.default_keywords['limit'])

    @property
    def facets(self):
        """ Returns list of facets.

        >>> esgf = ESGF()

        >>> esgf.facets # doctest:+ELLIPSIS
        ['project', ...]

        """
        if self._facets is None:
            project = self.default_facets.get('project', 'all')

            self._facets = facets.get_facets(preset=project.lower())

        return list(self._facets.keys())

    def facet_values(self, name):
        """ Returns a list of possible values for a facet.

        >>> esgf = ESGF()

        >>> esgf.facet_values('project') # doctest:+ELLIPSIS
        ['ACME', ...]

        """
        if name not in self.facets:
            data = facets.get_facets(facets=[name], **self.default_facets)

            return data

        return self._facets[name]

    def _parse_results(self, result):
        """ Parse JSON response.

        Extracts the record count and docs from the JSON response.
        """
        self.num_found = result['response']['numFound']

        return result['response']['docs']

    def _search(self, kwargs, raw=False):
        """ Performs search.

        Performs the search, loading the results into a `Pandas.DataFrame`. Scrubbing is done to format fields
        into human readable.
        """
        try:
            response = requests.get(self.base_url, params=kwargs)
        except Exception as e:
            raise SearchError('Server error {!s}'.format(e))

        if response.ok:
            data = self._parse_results(response.json())
        else:
            raise SearchError('Server returned {!r} status code {!r}'.format(response.status_code, response.text))

        df = pd.DataFrame.from_dict(data)

        if not raw:
            df = df.apply(column_reduce)

            if 'url' in df:
                url = df['url'].apply(pd.Series)

                gather = []

                for x in ('HTTPServer', 'GridFTP', 'Globus', 'OPENDAP'):
                    f = url.apply(lambda y: y.str.contains(x)).fillna(False)

                    gather.append(url[f].ffill(axis=1).iloc[:, -1].rename(x))

                df = pd.concat([df]+ gather, axis=1)

                del df['url']

        return df

    def search(self, *args, **kwargs):
        """ Performs search.

        Columns containing single value lists will be flattened otherwise the original value will be passed through.

        The URL column of each result will be expanded so each access type has its own column; HTTPServer, GridFTP, Globus, OPENDAP.

        To disable this scrubbing of the output pass the `raw` parameter set to `True`.

        >>> esgf = ESGF(facet_query={'project': 'CMIP5'})

        Facets applied with AND, variable='pr' and time_frequency='3hr'

        >>> result = esgf.search(variable='pr', time_frequency='3hr')

        Same name facets used with AND.

        >>> result = esgf.search(('variable', 'pr'), ('variable', 'prc'))

        Facets applied with OR, variable='pr' or variable='prw')

        >>> result = esgf.search(variable='pr,prw')

        Facet applied with NOT, variable!='pr' and variable!='prc'

        >>> result = esgf.search(('variable!', 'pr'), ('variable!', 'prc'))

        Args:
            raw (bool): Return results without scrubbing.
            *args: List of tuples.
            **kwargs: Search facets to use.
        """
        raw = kwargs.pop('raw', False)

        if len(args) > 0:
            self.params = list(args)

            self.params.extend(self.default_keywords.items())
            self.params.extend(self.default_facets.items())
        else:
            self.params = kwargs.copy()
            self.params.update(self.default_keywords)
            self.params.update(self.default_facets)

        self.page = 1

        return self._search(self.params, raw=raw)

    def _set_offset(self):
        if isinstance(self.params, list):
            try:
                index = [x[0] for x in self.params].index('offset')
            except ValueError:
                pass
            else:
                self.params.pop(index)

            self.params.append(('offset', self.page*self.default_keywords['limit']))
        else:
            self.params['offset'] = self.page*self.default_keywords['limit']

    def next(self):
        """ Retrieves next page of results.

        >>> esgf = ESGF(facet_query={'project': 'CMIP5'})

        >>> result = esgf.search(variable='pr', time_frequency='3hr')

        >>> result = esgf.next()

        """

        if self.page + 1 > self.pages:
            raise Exception('Your past the last page')

        self.page += 1

        self._set_offset()

        return self._search(self.params)

    def previous(self):
        """ Retrieves previous page of results.

        >>> esgf = ESGF(facet_query={'project': 'CMIP5'})

        >>> result = esgf.search(variable='pr', time_frequency='3hr')

        >>> result = esgf.next()

        >>> result = esgf.previous()

        """

        if self.page - 1 <= 0:
            raise Exception('Your past the first page')

        self.page -= 1

        self._set_offset()

        return self._search(self.params)


class CMIP5(ESGF):
    def __init__(self, **kwargs):
        facets = kwargs.pop('facets', {})

        facets.update(project='CMIP5')

        super(CMIP5, self).__init__(facet_query=facets, **kwargs)


class CMIP6(ESGF):
    """ ESGF search configured for CMIP6 project.

    >>> esgf = CMIP6()

    >>> esgf.default_facets
    {'project': 'CMIP6', 'query': '*'}

    """
    def __init__(self, **kwargs):
        facets = kwargs.pop('facets', {})

        facets.update(project='CMIP6')

        super(CMIP6, self).__init__(facet_query=facets, **kwargs)

