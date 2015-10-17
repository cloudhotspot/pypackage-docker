.. _Introduction:

Introduction
============

PyPackage Docker is a tool set for packaging Python and Django applications using Docker and Wheels.


Workflow
--------

|workflow|

Methodology
-----------

* Create deployable and versionable application artefacts (i.e. Python wheels)
* Create deployable and versionable operating environment artefacts (i.e. Docker images)
* Leverage Python standards and existing toolsets (``pip`` and ``virtualenv``) as much as possible
* Reduce build times by using cacheable pre-built application artefacts (i.e. Python wheels)


Prerequisites
-------------

PyPackage Docker uses a ``Makefile`` which restricts use to OS X and Linux.

PyPackage Docker requires the following:

* A Python application(s) to package
* Docker daemon (local or remote)
* Docker client 

PyPackage Docker was created and tested against Docker version 1.8.2.

Simplifying the Developer Experience
------------------------------------

All of the various tasks of building images, building packages and running release and development containers are performed using the ``docker`` command line tool.

The ``docker`` tool generally requires a number of inputs, which make it harder for new users to pick up quickly.

PyPackage Docker includes a |makefile| that simplifies the commands required to execute each of the various tasks to simple ``make`` commands.

.. |makefile| raw:: html

  <a href="https://github.com/cloudhotspot/pypackage-docker/blob/master/Makefile" target="_blank">Makefile</a>

Acknowledgements
----------------

The following articles contributed to the were key 



.. |workflow| image:: images/ci-workflow.png