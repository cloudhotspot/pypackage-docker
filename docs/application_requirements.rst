Application Requirements
========================

PyPackage Docker attempts to adopt Python best practices related to application packaging and folder structures.  In principle this means:

* Packages are built using the new standard of Python distribution - Wheels_.
* Everything is treated as a package - even Django projects

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

The ``packages = find_packages()`` setting allows packages to be found dynamically.  Any folder that includes the file ``__init__.py`` will be considered a package.

The ``scripts = ["manage.py"]`` setting configures the Django `manage.py` script to be installed at the `bin` folder in the virtual environment.  As this is in the PATH environment variable, any scripts can be executed from any location when the virtual envrionment is activated.

The ``include_package_data = True`` setting ensures that package data files such as templates and views are included in the application artefact.  Note these files must also be specified in `MANIFEST.in`.

The ``install_requires`` setting specifies all of the various Python package dependencies for the project.  This is analogous to the `requirements.txt` file often used in Django projects.

The ``extras_require`` setting allows you to define *conditional requirements*.  In the example above, a conditional requirement called **test** is defined which specifies a single package dependency.  This setting allows you to control if specific dependencies should be built.

At this point, you may be wondering how the ``requirements.txt`` paradigm often used in Django applications fits.  These can and should still exist, and there is a |good_discussion_here| as to how you should structure dependencies between ``setup.py`` and ``requirements.txt``.  At the most basic level, the following examples show how you can reference your ``setup.py`` dependencies from your ``requirements.txt`` files:

.. code-block:: none
  -e .

.. code-block:: none
  -e .[test]

.. _MANIFEST.in:
MANIFEST.in
~~~~~~~~~~~




.. _Wheels: http://wheel.readthedocs.org/en/latest/
.. |good_discussion_here| raw:: html
  <a href="https://caremad.io/2013/07/setup-vs-requirement/" target="_blank">good discussion here</a>