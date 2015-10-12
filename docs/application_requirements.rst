Application Requirements
========================

PyPackage Docker attempts to adopt Python best practices related to application packaging and folder structures.

In principle this means:

* Packages are built using the new standard of Python distribution - Wheels_.
* Everything is treated as a package - even Django projects

PyPackage Docker initially is focused at Django projects and as such, this document focuses on application requirements specific to Django projects.

However there is no reason why the requirements and principles described won't work for packaging other projects/applications.

Project Root
------------

At a minimum, the project root of your Django project requires the following files:

* setup.py
* MANIFEST.in
* README.rst
* LICENSE


setup.py
~~~~~~~~

The ``setup.py`` file provides the specification of how to build your application into package(s).  

A sample setup.py_ file is included in the PyPackage Docker repository::
  
  from setuptools import setup, find_packages

  setup (
      name                 = "SampleDjangoApp",
      version              = "0.1",
      description          = "Example Django Application",
      packages             = find_packages(),
      scripts              = ["manage.py"],
      include_package_data = True,
      install_requires     = ["Django>=1.8.5",
                              "uwsgi>=2.0"],
      extras_require       = {
                                "test": ["coverage"],
                             },
  )




.. _Wheels: http://wheel.readthedocs.org/en/latest/