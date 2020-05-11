.. esgf-search documentation master file, created by
   sphinx-quickstart on Mon May 11 14:57:12 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to esgf-search's documentation!
=======================================

.. toctree::
   :hidden:
   :maxdepth: 2

   esgf
   facets

The esgf-search module provides classes to interface with the ESGF search API and retrieve facet presets.

Full documentation of the API can be found `here <https://earthsystemcog.org/projects/cog/esgf_search_restful_api>`_.

Install
-------
.. code-block:: bash

   conda install -c conda-forge -c cdat esgf-search


Quickstart
----------

General search
^^^^^^^^^^^^^^

>>> import esgf_search

>>> esgf = esgf_search.CMIP5()

>>> esgf.search(variable='tas', time_frequency='3hr')

List facets
^^^^^^^^^^^

>>> esgf.facets
[..., "ACME", ...]

List values for facet
^^^^^^^^^^^^^^^^^^^^^

>>> esgf.facet_values('time_frequency')
[..., "3hr", ...]

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
