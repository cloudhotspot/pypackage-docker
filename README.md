# Python Packager

A methodology for packaging Python and Django applications using Docker and Wheels.

## Quick Start

The basic workflow is as follows:

- Prepare your application
- Configure your environment
- Create base image - `make image docker/base`
- Create builder image - `make image docker/builder`
- Build application packages - `make build`
- Create application image - `make release`
- Run application image - `make run <command>` or `make manage <manage.py command>`

### Preparing your Application

Your application requires a `setup.py` and `MANIFEST.in` file in the project root.

Here is the sample application `setup.py` file:

```python
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
```

You must include your application dependencies in the `install_requires` setting.  The `extras_require` setting allows you to specify conditional dependencies.  Refer to the <a href="http://pypackage-docker.readthedocs.org/en/latest/application_requirements.html#setup-py" target="_blank">documentation</a> for more information.

Here is the sample `MANIFEST.in` file:

```text
recursive-include polls/templates *
recursive-include polls/static *
recursive-include templates *
```

In conjunction with the `include_package_data = True` setting in `setup.py`, this ensures template files, views and other content will be included in your application packages.

### Configuring your Environment

This repository includes a `Makefile` that simplifies the commands you need to enter to perform the various tasks.

The `Makefile` relies on a number of different environment settings.  These settings can all be configured by setting the environment variable to an appropriate value:

- REPO_NS - the namespace used to build Docker images.  Set this to your Docker hub organization name.  The default namespace value is **cloudhotspot**.
- REPO_VERSION - the version to tag to built Docker images.  By default this is set to **latest**.
- IMAGE_NAME - the image name used to build Docker images.  Set this to a name that describes your application.  The default image name is **sampledjangoapp**
- PORTS - a space limited set of port mappings that will applied to any underlying `docker run` command.
- VOLUMES - a space limited set of volume mappings that will applied to any underlying `docker run` command.
- ENV_VARS - a space delimited set of environment variables that will applied to any underlying `docker run` command.

For example:

```bash
$ export REPO_NS=example
$ export IMAGE_NAME=myapp
$ export REPO_VERSION=1.0
$ export PORTS="8000:8000 8443:443"
$ export VOLUMES="/host/data/path:/container/data/path"
$ export ENV_VARS="MY_CUSTOM_VAR1=my_custom_value_1 MY_CUSTOM_VAR2=my_custom_value_2"
```

In the example above, whenever `docker run` is called (e.g. using `make run`) the `docker run` command will execute as follows:

```bash
$ docker run -it --rm -p 8000:8000 -p 8443:8443 \
    -e MY_CUSTOM_VAR1=my_custom_value_1 -e MY_CUSTOM_VAR2=my_custom_value_2 \
    example/myapp:1.0 <command>
```

### Creating the Base Image

The base image is the parent image from which all other images are built.  Accordingly, the base image should:

- Include common operating system packages and settings applicable to all child images.  
- Create the virtual environment 
- Include an entrypoint that activates the virtual environment and executes arbitray commands within the virtual environment

The <a href="https://github.com/cloudhotspot/pypackage-docker/blob/master/docker/base/Dockerfile" target="_blank">sample base image</a> includes all of the above.  

The base image is built using the `make image <path/to/dockerfile-folder> [<path/to/image/path>]`` command.

To build the sample base image:

`make image docker/base`

This will result in the following Docker command being executed:

`docker build -t $REPO_NS/$REPO_NAME-base:$VERSION -f /docker/base/Dockerfile /docker/base`

> Note that the `base` portion of the `docker/base` path determines the *image context*, which is appended to the Docker image name to differentiate between base, build and other images.

See the <a href="http://pypackage-docker.readthedocs.org/en/latest/creating_base_images.html" target="_blank">documentation</a> for more details.

### Creating the Builder Image

The builder image is responsible for building application packages as Python wheels.  

The builder image should include operating system packages, tools and settings applicable to building the target application package and all development, test and production dependencies.

The builder image is built using the `make image <path/to/dockerfile-folder> [<path/to/image/path>]`` command.

To build the <a href="https://github.com/cloudhotspot/pypackage-docker/blob/master/docker/builder/Dockerfile" target="_blank">sample builder image</a>:

`make image docker/builder`

This will result in the following Docker command being executed:

`docker build -t $REPO_NS/$REPO_NAME-builder:$VERSION -f /docker/build/Dockerfile /docker/build`

> Note that the `builder` portion of the `docker/builder` path determines the *image context*, which is appended to the Docker image name to differentiate between base, build and other images.

See the <a href="http://pypackage-docker.readthedocs.org/en/latest/creating_builder_images.html" target="_blank">documentation</a> for more details.

### Building Packages

Once the builder image created in the previous section is run you should have the base and builder Docker images in place:

```bash
$ docker images
REPOSITORY                             TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
cloudhotspot/sampledjangoapp-builder   latest              e2038a7c10d0        19 hours ago        366.7 MB
cloudhotspot/sampledjangoapp-base      latest              4ad1d509a823        20 hours ago        253 MB
...
```

You can now build your application and dependency packages using the `make build` command:

`make build [<conditional-requirement> | cmd <command-string>]

The `make build` command will:

- Build your application
- Build any dependencies defined in the `install_requires` setting of your `setup.py` file.
- Output the built wheels to the `wheelhouse` folder

The `make build test` command will:

- Build your application
- Build any dependencies defined in the `install_requires` setting of your `setup.py` file.
- Build any dependencies defined with the `test` identifer of the `extras_require` setting of your `setup.py` file.
- Output the built wheels to the `wheelhouse` folder

The `make build cmd <command-string>` command will:

- Execute the supplied command string against the builder container

> The current `Makefile` requires your application source to be located within the `src` folder of the project root.

See the <a href="http://pypackage-docker.readthedocs.org/en/latest/building_packages.html" target="_blank">documentation</a> for more details.

### Creating Application Images

To build your production image, simply execute `make release`.  This requires a `Dockerfile` defined at the project root.



### Running your Application

To run your application, use the `make run` or `make manage` commands:

- `make run <command-string>`
- `make manage <django-admin-command>`

Examples:

```bash
# Get an interactive prompt
$ make run bash
docker run -it --rm -p 8000:8000  cloudhotspot/sampledjangoapp:latest bash
root@a584b6cb23a6:/# manage.py check
System check identified no issues (0 silenced).
root@a584b6cb23a6:/# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=127 time=39.0 ms
```

```bash
# Run migrations
$ make manage migrate
docker run -it --rm -p 8000:8000 cloudhotspot/sampledjangoapp:latest manage.py migrate
Operations to perform:
  Synchronize unmigrated apps: staticfiles, messages
  Apply all migrations: admin, contenttypes, polls, auth, sessions
Synchronizing apps without migrations:
  Creating tables...
    Running deferred SQL...
  Installing custom SQL...
Running migrations:
  Rendering model states... DONE
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying contenttypes.0002_remove_content_type_name... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying auth.0003_alter_user_email_max_length... OK
  Applying auth.0004_alter_user_username_opts... OK
  Applying auth.0005_alter_user_last_login_null... OK
  Applying auth.0006_require_contenttypes_0002... OK
  Applying polls.0001_initial... OK
  Applying sessions.0001_initial... OK
```

```bash
# Run collectstatic
 make -- manage collectstatic --noinput
docker run -it --rm -p 8000:8000 cloudhotspot/sampledjangoapp:latest manage.py collectstatic --noinput
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/css/base.css'
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/css/rtl.css'
...
63 static files copied to '/var/www/mysite/static'.
```

> Use the `--` separate after the `make` command to allow any subsequent arguments to be passed to the `docker run` command, rather than being interpreted by the `make` command as arguments



#### `make image`

Creates a Docker image using the `docker build` command.  The executed command is:

`docker build -t $REPO_NS/$REPO_NAME:$VERSION -f ./Dockerfile .`

which is equivalent to:

`docker build -t $REPO_NS/$REPO_NAME:$VERSION .`

> A Dockerfile must be present in the project root for `make image` to work

#### `make image <path/to/dockerfile> [<path/to/build/path>]`

Creates a Docker image using the `docker build` command.  

`<path/to/dockerfile>` represents the path to the folder containing the Dockerfile.

`<path/to/build/path>` optionally represents the path to where any files added in the Dockerfile should be sourced from.  If this is omitted, the build path is assumed to be the same as `<path/to/dockerfile>`

### Building Artefacts

#### `make build` 

Builds application artefacts and dependencies as specified in the `install_requires` section of `setup.py`.  

This executes the command:

`docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse $REPO_NS/$REPO_NAME-build:$VERSION `


#### `make build <conditional requirement>`

Builds application artefacts and dependencies as specified in the `install_requires` section of `setup.py`, along with additional dependencies defined by the `<conditional requirement>` envrionment specifier in the `extras_require` section of `setup.py`.

This executes the command:

`docker run --rm -v "$(pwd)"/src:/application -v "$(pwd)"/wheelhouse:/wheelhouse $REPO_NS/$REPO_NAME-build:$VERSION pip wheel .[<conditional requirement>]`

For example, given the following setup.py snippet:

```python
setup.py (
...
install_requires = ["Django>=1.8.5",
                    "uwsgi>=2.0"],
extras_require   = {
                      "test": ["coverage"],
                   },
...
)
```

`make build` will create only the `Django` and `uwsgi` dependency artefacts.  `make build test` will create `Django`, `uwsgi` and `coverage` dependency artefacts.

> If an invalid conditional requirement is specified, it is ignored gracefully and the result will be the same as `make build`

#### `make build cmd <command string>`

Runs arbitrary commands as specified by the `<command string>` in the builder image.


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

## TODO

- Add support to pass environment variables
- Add support for modular settings
- Add example for creating dev/test images