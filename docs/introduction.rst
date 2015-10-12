.. _Introduction:

Introduction
============

PyPackage Docker is a tool set for packaging Python and Django applications using Docker and Wheels.

Methodology
-----------


Prerequisites
-------------

The only requirement is access to a Docker host (either local or remote).

PyPackage Docker has been tested against Docker version 1.8.2.


Simplifying the Developer Experience
------------------------------------

All of the various tasks of building images, building packages and running release and development containers are performed using the ``docker`` command line tool.

The ``docker`` tool generally requires a number of inputs, which make it harder for new users to pick up quickly.

PyPackage Docker includes a |makefile| that simplifies the commands required to execute each of the various tasks to simple ``make`` commands.

.. |makefile| raw:: html

  <a href="https://github.com/cloudhotspot/pypackage-docker/blob/master/Makefile" target="_blank">Makefile</a>