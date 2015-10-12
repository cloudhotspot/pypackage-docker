Application Requirements
========================

PyPackage Docker attempts to adopt Python best practices related to application packaging and folder structures.  In principle this means:

* Packages are built using the new standard of Python distribution (|wheels_link|).
* Everything is treated as a package - even Django projects.

PyPackage Docker initially is focused at Django projects and as such, this document focuses on application requirements specific to Django projects.

However there is no reason why the requirements and principles described won't work for packaging other projects/applications.

Project Root
------------

At a minimum, the project root of your Django project requires the following files:

* :ref:`setup.py`
* :ref:`MANIFEST.in`
* README.rst
* LICENSE

The README.rst and LICENSE files are self explanatory and below we will just discuss the `setup.py` and `MANIFEST.in` files.

.. _setup.py:

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


The following discusses important settings in the ``setup.py`` file:

* ``packages = find_packages()`` - allows packages to be found dynamically.  Any folder that includes the file ``__init__.py`` will be considered a package.

* ``scripts = ["manage.py"]`` - configures the Django `manage.py` script to be installed at the `bin` folder within the PATH environment variable in the target physical/virtual environment.  This allows the specified scripts to be executed from any location within the target physical/virtual environment.

* ``include_package_data = True`` - ensures that package data files such as templates and views are included in the application package.  Note these files must also be specified in `MANIFEST.in`.

* ``install_requires`` - specifies all of the various Python package dependencies for the project.  This is analogous to the ``requirements.txt`` file often used in Django projects.

* ``extras_require`` - allows you to define *conditional requirements*.  In the example above, a conditional requirement called **test** is defined which specifies a single package dependency.  This setting allows you to control if specific dependencies should be built.

At this point, you may be wondering how the ``requirements.txt`` paradigm often used in Django applications fits in.  

These files can and should still exist, and there is a |good_discussion_here| as to how you should structure dependencies between ``setup.py`` and ``requirements.txt``.  

At the most basic level, the following examples show how you can reference your ``setup.py`` dependencies from your ``requirements.txt`` files:

.. code-block:: python

  # requirements.txt
  -e .

.. code-block:: python

  # requirements-test.txt
  -e .[test]

.. _MANIFEST.in:

MANIFEST.in
~~~~~~~~~~~

The ``MANIFEST.in`` file specifies which data files should be included in the application package(s). 

.. note:: The ``include_package_data = true`` setting must be present in ``setup.py`` for the ``MANIFEST.in`` configuration to be applied

The example ``MANIFEST.in`` file included with the sample application ensures all subdirectories and files in the following locations (relative to the application root) will be included in the application package(s):

* ``polls/templates``
* ``polls/static``
* ``templates``

.. code-block:: python

  # MANIFEST.in
  recursive-include polls/templates *
  recursive-include polls/static *
  recursive-include templates *

Application Packages
--------------------

All applications that are to be packaged under the root project folder must include an empty ``__init__.py`` file within the top-level folder of the application.  This includes the project package which includes ``settings.py``, ``urls.py`` and ``wsgi.py``.

By default, any application created via the Django admin tools within a project includes an ``__init__.py`` file, so the application will be packaged and no manual intervention is included.

The ``setup.py`` file uses the ``packages = find_packages()`` setting to automatically locate all applications within the project.

.. note:: |this_repository| includes the |django_sample_application|, which creates a project package called ``mysite`` and a supporting application package called ``polls``.


.. |wheels_link| raw:: html

  <a href="http://wheel.readthedocs.org/en/latest/" target="_blank">wheels</a>

.. |good_discussion_here| raw:: html

  <a href="https://caremad.io/2013/07/setup-vs-requirement/" target="_blank">good discussion here</a>

.. |this_repository| raw:: html

  <a href="https://github.com/cloudhotspot/pypackage-docker" target="_blank">The Github repository for PyPackage Docker</a>

.. |django_sample_application| raw:: html

  <a href="https://docs.djangoproject.com/en/1.8/intro/tutorial01/" target="_blank">Django sample application</a>