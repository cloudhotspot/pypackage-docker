Creating the Base Image
=======================

Introduction
------------
The base image is the foundation for all other images.  

This image should include common packages and configuration used for all other images including:

* Builder images
* Development images
* Production (Release) images

.. note:: It is quite possible (and probably recommended to reduce complexity) that a base image may span mutiples projects.  Always strive for reusability where possible.

.. _building-the-base-image:

Building the Base Image
-----------------------

To build the base image, use the ``make image`` command as follows:

``make image docker/base``

The **docker/base** argument is the relative path to the folder where the base image Dockerfile is located.  Under the hood the ``make image docker/base`` command is calling:

`docker build -t cloudhotspot/sampledjangoapp-base:latest -f docker/base/Dockerfile docker/base`

The naming of the **base** folder is important as the ``Makefile`` uses this as a convention to set attach a build context to the base image name.

For example, assuming the following environment configuration:

* REPO_NS = cloudhotspot
* IMAGE_NAME = sampledjangoapp
* VERSION = latest

Running ``make image docker/base`` will create an image tagged as follows:

* **cloudhotspot/sampledjangoapp-base:latest**

If your base image Dockerfile was located in **docker/foundation**, then ``make image docker/foundation`` would create the following image:

* **cloudhotspot/sampledjangoapp-foundation:latest**

Base Image Internals
--------------------

The |sample_base_image| in the PyPackage repository is located in the **docker/base** folder and includes the following files:

* Dockerfile
* entrypoint.sh

Dockerfile
~~~~~~~~~~

The sample Dockerfile for the base image is listed below:

.. code-block:: bash

  FROM ubuntu:trusty
  MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

  # Set mirrors to NZ and install common packages
  RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list && \
      apt-get update && \
      apt-get install -qyy -o APT::Install-Recommends=false -o APT::Install-Suggests=false python-virtualenv python libffi6 openssl libpython2.7

  # Create virtual environment
  RUN virtualenv /appenv

  # Upgrade PIP
  RUN . /appenv/bin/activate; pip install pip==7.1.2

  # Activate the virtual environment
  ADD entrypoint.sh /usr/local/bin/entrypoint.sh
  RUN chmod +x /usr/local/bin/entrypoint.sh
  ENTRYPOINT ["entrypoint.sh"]

As you can see, the base image is based from the official Ubuntu Trusty Docker image and includes the following packages:

* python (Python 2.7)
* python-virtualenv
* openssl
* libpython2.7
* libffi6

The base image also:

* Creates a virtual environment
* Installs a recent version of PIP in the virtual environment
* Adds the ``entrypoint.sh`` shell script as the entrypoint for the image (discussed below) 

entrypoint.sh
~~~~~~~~~~~~~

The **entrypoint.sh** shell script is very simple:

.. code-block:: bash

  #!/bin/bash
  . /appenv/bin/activate
  exec $@

All this script does is simply activate the virtual environment and then execute any arguments passed to the script.  This leverages the behaviour of Docker entrypoints, where any arguments passed at the end of the ``docker run`` command are passed as arguments to the image entrypoint.  

This allows arbitrary commands to be run within the virtual environment, increasing the utility of the image.  For example, the following executes the command ``pip -V`` in the Docker container to display the installed ``pip`` version:

.. code-block:: bash

  $ docker run -it --rm cloudhotspot/sampledjangoapp-base pip -V
  pip 7.1.2 from /appenv/local/lib/python2.7/site-packages (python 2.7)

.. note:: Using ``exec`` ensures the command executed will run as PID 1 in the Docker container (rather than the bash shell).  This is important for ensuring the container can exit and shutdown cleanly. 


.. |sample_base_image| raw:: html

  <a href="https://github.com/cloudhotspot/pypackage-docker/tree/master/docker/base" target="_blank">sample base image</a>

