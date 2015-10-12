.. _creating_the_builder_image

Creating the Builder Image
==========================

Introduction
------------

The builder image is used for building packages (Python wheels).  

This requires the builder image to include all build dependencies for the various types of application images that need to be created.  This should include all development and test build dependencies, so that builder can create the following types of packages:

* Production package dependencies
* Development package dependencies
* Test package dependencies

Building the Builder Image
-----------------------

To build the builder image, use the ``make image`` command as follows:

``make image docker/builder``

The **docker/builder** argument is the relative path to the folder where the builder image Dockerfile is located.  Under the hood the ``make image docker/builder`` command is calling:

``docker build -t cloudhotspot/sampledjangoapp-builder:latest -f docker/builder/Dockerfile docker/builder``

which will publish an image tagged ``$(REPO_NAME)/$(IMAGE_NAME)-$(IMAGE_CONTEXT):$(VERSION)``.  

.. note:: The naming of the **builder** folder is important for the same reasons discussed previously in :ref:`building-the-base-image`

Builder Image Internals
-----------------------

The |sample_builder_image| in the PyPackage repository is located in the **docker/builder** folder and includes a single ``Dockerfile``:

.. code-block:: bash

  FROM cloudhotspot/sampledjangoapp-base
  MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

  # Install build dependencies
  RUN apt-get install -qy libffi-dev libssl-dev python-dev && \
      . /appenv/bin/activate && \
      pip install wheel 
      
  # PIP environment variables (NOTE: must be set after installing wheel)
  ENV WHEELHOUSE=/wheelhouse PIP_WHEEL_DIR=/wheelhouse PIP_FIND_LINKS=/wheelhouse

  # OUTPUT: Build artefacts (Wheels) are output here
  VOLUME /wheelhouse

  # INPUT: The application/project root to build from
  VOLUME /application
  WORKDIR /application

  CMD ["pip", "wheel", "."]

The builder image is based from the base image and includes the following development/build related packages:

* libffi-dev 
* libssl-dev
* python-dev

The builder image also:

* Installs the ``wheel`` Python package
* Sets environment variables used by ``pip`` to build wheels
* Creates a volume ``/application`` which is intended to be used to mount application source code from which packages will be built.
* Creates a volume ``/wheelhouse`` which is where all built packages (wheels) will be output
* Sets default command to ``pip wheel .`` which will build the application and all install_requires dependencies specified in ``setup.py``

.. |sample_builder_image| raw:: html

  <a href="https://github.com/cloudhotspot/pypackage-docker/tree/master/docker/builder" target="_blank">sample builder image</a>
