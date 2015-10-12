Building Packages
=================

Once you have created a builder image (see :ref:`creating_the_builder_image`), the builder image can be used to build and package your application and its dependencies.

Building Release Packages
-------------------------

To build the application and all of its *release* (install_requires) dependencies specified in ``setup.py``:

``make build``

This executes the following command under the hood:

``docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse \
      cloudhotspot/sampledjangoapp-build:latest`` 

.. important:: The ``Makefile`` currently requires your application to be in the ``src`` folder under the project root for the ``make build`` commands to work.

The builder container runs ``pip wheel .`` in the ``/application`` container folder, which is mounted to the application source directory.  This will create wheels both for the application and its dependencies in the ``wheelhouse`` folder under the project root.

Building Test/Dev Packages
--------------------------

To build the application, its *release* (install_requires) dependencies and other dependencies (extras_require) such as test/development dependencies specified as a *conditional identifier* in ``setup.py``:

``make build <conditional identifier>``

For example, assuming the following ``setup.py`` file, which includes a ``test`` conditional identifier in the extras_require setting:

.. code-block:: python

  from setuptools import setup, find_packages

  setup (
  ...
      install_requires     = ["Django>=1.8.5",
                              "uwsgi>=2.0"],
      extras_require       = {
                                "test": ["coverage"],
                             },
  ...
  )

``make build`` would build packages for the application and the following dependencies:

* Django
* uwsgi

``make build test`` would build packages for the application and the following dependencies:

* Django
* uwsgi
* coverage

Under the hood, the following command is being executed for ``make build test``:

``docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse \ 
    cloudhotspot/sampledjangoapp-build:latest pip wheel .[test]`` 

You can see that the conditional identifier is passed to the ``pip wheel`` command in square brackets.

-- note: If an invalid conditional identifier is specified, ``pip`` ignores the identifier and runs the equivalent of ``pip wheel .`` instead.

Running Custom Commands
-----------------------

You can run custom commands against builder containers using the following command:

``make build cmd <command string>``

For example:

.. code-block:: bash

  $ make -- build cmd pip -V
  docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse \ 
    cloudhotspot/sampledjangoapp-builder:latest pip -V
  pip 7.1.2 from /appenv/local/lib/python2.7/site-packages (python 2.7)

Note the use of the ``--`` following the ``make`` command.  This tells the local shell that all of the following arguments should not be interpreted as arguments to the ``make`` command.