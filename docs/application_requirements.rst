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

* ``setup.py``
* ``MANIFEST.in``
* ``README.rst``
* ``LICENSE``


``setup.py``
------------

The setup.py

.. _wheels: http://wheel.readthedocs.org/en/latest/