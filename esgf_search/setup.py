import esgf_search
from setuptools import find_packages, setup

setup(
    name="esgf-search",
    version=esgf_search.__version__,
    install_requires=["requests", "pandas"],
    test_requires=["pytest"],
    packages=find_packages(),
)
