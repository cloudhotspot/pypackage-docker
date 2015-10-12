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

`docker build -t cloudhotspot/sampledjangoapp-builder:latest -f docker/builder/Dockerfile docker/builder`

which will publish an image tagged ``$(REPO_NAME)/$(IMAGE_NAME)-$(IMAGE_CONTEXT):$(VERSION)``.  

.. note:: The naming of the **builder** folder is important for the same reasons discussed previously in :ref:`building-the-base-image`

Builder Image Internals
-----------------------

