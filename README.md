# Python Packager

A methodology for packaging Python and Django applications using Docker and Wheels.

## Introduction


## Base Image

The base image is the foundation for all other images.  This image should include common packages and configuration used for both development and production images.

The sample base image in this repository is located in `docker/base`.  

The base image is based from the official Ubuntu Trusty Docker image and includes the following packages:

- python (Python 2.7)
- python-virtualenv
- openssl
- libpython2.7
- libffi6

The sample base image also includes the following:

- A virtual environment is created at `/appenv`
- An entrypoint script called `entrypoint.sh`

The `entrypoint.sh` is a simple bash script that activates the virtual environment and executes the arguments passed to the script: 

```bash
#!/bin/bash
. /appenv/bin/activate
exec $@
```

This script allows you to pass in a command to a Docker container run from the image, which will run in the virtual environment.  

In the example below, the `env` command demonstrates that the command is being executed in the virtual environment.

```bash
$ pypackage jmenga$ docker run -it --rm pypackage-base env
HOSTNAME=2df33790f98e
TERM=xterm
VIRTUAL_ENV=/appenv
PATH=/appenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/
PS1=(appenv)
SHLVL=0
HOME=/root
```

Any image that is built from the base image inherits the entrypoint script as the default entrypoint, unless explicitly overridden.

### Creating the Base Image

A `Makefile` is included that provides shortcuts for the various Docker commands.

To build the base image from the project root:

`make image docker/base`

Under the hood this is calling:

`docker build -t pypackage-base -f docker/base/Dockerfile docker/base`

In general, the base image should be built infrequently and likely will be common to multiple projects.

## Builder Image

The purpose of the builder image is to compile and build application artefacts for your Python application.  

The builder image must include all build dependencies required to compile and build the application. 

The sample builder image in this repository is located in `docker/builder` and includes the following:

- libffi-dev
- libssl-dev
- python-dev 
- `wheel` package (i.e. `pip install wheel`)

The builder image also includes two volumes:

- `/application` - this is where the image will look for application source code that will be built into packages
- `/wheelhouse` - this is where the image will output built application artefacts (wheels)

The builder image specifies `/application` as its default working directory and passes in `pip wheel .` as the default command arguments, which will automatically build the applications in `/application`.

### Creating the Builder Image

To build the builder image from the project root:

`make image docker/builder`

Under the hood this is calling:

`docker build -t pypackage-builder -f docker/builder/Dockerfile docker/builder`

In general, the builder image should be built fairly infrequently and may be common to multiple projects.

## Release Images

Release images are intended for production environments.  They are built in two stages as follows:

- Builder image is run, which creates application artefacts
- Release image is built, installing the built application artefacts in a Docker image that only contains production dependencies

### Building the Application Artefacts

Application artefacts are built as wheels using the builder image.  This involves running the builder image with the following parameters:

- The application source code root mapped to the `/application` volume
- A folder mapped to the `/wheelhouse` volume.  This is where the builder image will output the artefacts.

Here is an example of running the builder image:


`docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse pypackage-builder`



Create base image:

`docker build -t pypackage-base -f docker/base/Dockerfile docker/base`

Create build image:

`docker build -t pypackage-build -f docker/build/Dockerfile .`

Create build:

`docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse pypackage-build`

Create release image:

`docker build -t pypackage-sampleapp .`

Run application release

`docker run -it --rm -p 8000:8000 pypackage-sampleapp`

uwsgi --http :8000 --module mysite.wsgi --static-map /static=/var/www/mysite/static