import configparser

import requests


BASE_URL = 'https://raw.githubusercontent.com/ESGF/config/master/search-configs/search'

PRESETS = {
    'all': '',
    'cc4e': 'cc4e',
    'cmip5': 'cmip5',
    'cmip6': 'cmip6',
    'cordex': 'cordex',
    'input4mips': 'input4mips',
    'isimip-ft': 'isimip-ft',
    'obs4mips': 'obs4mips',
    'specs': 'specs',
}


class FacetError(Exception):
    pass


class UnknownPresetError(FacetError):
    def __init__(self, key):
        fmt = 'Unknown preset {!s}, available options {!s}'

        err_msg = fmt.format(key, ', '.join(PRESETS.keys()))

        super(UnknownPresetError, self).__init__(err_msg)


def _get_config(name):
    try:
        variant = PRESETS[name.lower()]
    except KeyError as e:
        raise UnknownPresetError(e)

    if variant == '':
        url = '{base_url}.cfg'
    else:
        url = '{base_url}_{variant}.cfg'

    url = url.format(base_url=BASE_URL, variant=variant)

    response = requests.get(url)

    config = configparser.ConfigParser()

    try:
        config.read_string(response.text)
    except configparser.MissingSectionHeaderError:
        return None

    return config


def _load_config(name):
    config = _get_config(name)

    data = {}

    for s in config.sections():
        if s == 'GLOBAL':
            continue

        title = s.split('=')[1]

        values = [config[s][x].split('|')[0] for x in config[s]]

        if title in data:
            data[title].extend(values)
        else:
            data[title] = values

    return data


def get_facets(name=None, include_counts=False, overwrite=False, **kwargs):
    if name is None:
        name = 'all'

    search_params = {
        'format': 'application/solr+json',
        'limit': '0',
        'project': [],
        'facets': [],
    }

    config = _load_config(name)

    for x_name, x in config.items():
        search_params['facets'].extend(x)

    search_params['facets'] = ','.join(search_params['facets'])

    search_params.update(kwargs)

    search_url = 'https://esgf-node.llnl.gov/esg-search/search'

    response = requests.get(search_url, params=search_params)

    try:
        fields = response.json()['facet_counts']['facet_fields']
    except KeyError:
        return None

    if not include_counts:
        fields = dict((x, y[::2]) for x, y in fields.items())

    return fields
