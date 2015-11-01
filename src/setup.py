
from setuptools import setup, find_packages

setup (
    name                 = "SampleDjangoApp",
    version              = "0.1",
    description          = "Example Django Application",
    packages             = find_packages(),
    scripts              = ["manage.py"],
    include_package_data = True,
    install_requires     = ["Django>=1.8.5",
                            "uwsgi>=2.0",
                            "mysql-python"],
    extras_require       = {
                              "test": [
                                "coverage",
                                "django-nose"
                              ],
                           },
)

