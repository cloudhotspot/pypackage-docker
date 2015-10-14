# Python Packager

A methodology for continuous integration and packaging of Python and Django applications using <a href="http://wheel.readthedocs.org/en/latest/" target="_blank">Python Wheels</a> and <a href="https://www.docker.com" target="_blank">Docker</a>. 

Full documentation is provided at <a href="http://pypackage-docker.readthedocs.org">read the docs</a>.  

The goals of this methodology include:

- Portable workflow - you should be able to run this workflow locally on a developer machine or on a CI system like Jenkins.
- Create a Python virtual environment (even when containers, <a href="https://hynek.me/articles/virtualenv-lives/" target="_blank">see why here</a>).
- Create deployable **native** application artefacts (i.e. Python Wheels, not archives or operating system packages).
- Create deployable runtime environment artefacts (i.e. Docker images). 
- Create simple to maintain manifests that describe application and runtime environment dependencies.
- Eliminate development and test dependencies from production runtime environment artefacts.
- Fast developer feedback - accelerate testing and build activities through Python Wheels caching.
- Ease of use - reduce complexity of running long Docker commands to simple `make` style commands.
- Reusability - use Docker image layering to build dependency and configuration trees that promote reusability
- Leverage familiar Python tooling - use of `pip` and `virtualenv` means this it is possible to extract this workflow outside of Docker

## Workflow

The initial setup to get started is as follows:

- Prepare your application
- Configure your environment
- Create base image
- Create builder image
- Create test image

With the above in place, the CI workflow can take place.  The CI workflow is triggered on each source code commit and thus benefits the most from automation and performance optimisations.

The CI workflow (assuming all tests pass) is as follows:

- Commit to source code repository 
- Install application and run unit tests (using test image container)
- Build application artefacts (using builder image container)
- Build runtime environment artefacts 
- Deploy sandbox environment for the full application stack (e.g. including databases, caches)
- Run functional/integration tests against sandbox
- Publish application and runtime environment artefacts 

This project demonstrates the workflow outlined above, providing the ability to execute each step on any Linux/OS X machine running a Docker client with access to a Docker host.  This workflow can also be automated within a CI system such as Jenkins, triggered by a commit to the source code repository for the application.

## Quick Start

The following provides an example to enable you to get started, and assumes you are using the included sample application located in the `src` folder.  For further information on how to prepare your application for this workflow, refer to the <a href="http://pypackage-docker.readthedocs.org/en/latest/application_requirements.html" target="_blank">documentation</a>.

### Prerequisites

- Linux/OS X computer
- Docker client (the workflow has been tested on Docker 1.8)
- Docker daemon (either running locally, on local VM or on a remote host)
- Docker daemon must have Internet connectivity

### Initial Setup

Configure your environment either by setting environment variables or by configuring the `Makefile`:

```bash 
REPO_NS ?= mycompany
REPO_VERSION ?= latest
IMAGE_NAME ?= myapp
PORTS ?= 8000:8000

.PHONY: image build release run manage clean test
...
...
```

Create the base image using the `make image docker/base` command.  

The base image should include any common dependencies/configuration settings to both development/test images and production images.  

The base image includes an entrypoint script `entrypoint.sh` that activates the Python virtual environment and runs any command in the virtual environment.  This entrypoint is inherited by all child images, promoting reusability.

```bash
$ make image docker/base
Sending build context to Docker daemon  7.95 MB
Step 0 : FROM ubuntu:trusty
 ---> 91e54dfb1179
 ...
 ...
Removing intermediate container 3fb1b4fbbb97
Successfully built 7d763df4a3b4
make: `docker/base' is up to date.
```

Create the builder image using the `make image docker/builder` command.  The builder image should include all dependencies required for development and build purposes.

> You must ensure the `FROM` directive in `docker/builder/Dockerfile` references the correct base image and version (see Step 0 below):

```bash
$ make image docker/builder
Sending build context to Docker daemon 7.951 MB
Step 0 : FROM mycompany/myapp-base:latest
 ---> 333bb56f3d69
...
...
Removing intermediate container 3fb1b4fbbb97
Successfully built 9599b05c1a22
make: `docker/builder' is up to date.
```

Create the test image using the `make image docker/test` command.  The test image should include any test dependencies and uses the `test.sh` entrypoint script, which activates the virtual environment, installs the application and then runs a command string (by default `python manage.py test`):

```bash
$ make image docker/test
Sending build context to Docker daemon 1.581 MB
Step 0 : FROM mycompany/myapp-builder
 ---> ef81e12cb16b
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Running in 84781ffee27e
 ---> 326b2fcede26
Removing intermediate container 84781ffee27e
Step 2 : ADD test.sh /usr/local/bin/test.sh
 ---> 05e2a72e60ec
Removing intermediate container 61b24fdefef2
Step 3 : RUN chmod +x /usr/local/bin/test.sh
 ---> Running in d79c90cabb06
 ---> cad5f490062d
Removing intermediate container d79c90cabb06
Step 4 : ENTRYPOINT test.sh
 ---> Running in f8a2a99bab08
 ---> 40bbbafae1fc
Removing intermediate container f8a2a99bab08
Step 5 : CMD python manage.py test
 ---> Running in 8f6ee2acfb47
 ---> cc965753e601
Removing intermediate container 8f6ee2acfb47
Successfully built cc965753e601
make: `docker/test' is up to date.
```

### Continuous Integration Workflow

With the application, environment and base/builder/test images in place, the normal continuous integration workflow can be executed.  This workflow would typically be invoked on each application source code commit in a production continuous integration system.  

However it is possible to complete the steps described below manually on a development machine as required.

On each commit, the continuous integration workflow starts by running tests inside the test container using the `make test` command.  

This will install the application and run `python manage.py test` in a container based upon the test image:

> The Makefile automatically creates a volume container that stores the pip cache.  This allows subsequent invocations of `make test` and `make build` to use cached dependencies for much faster execution times (see example below where the first run of `make test` takes 39 seconds, whilst the second run takes just under 6 seconds).  The `make clean` command removes application build artefacts and the pip cache volume container.

```bash
$ time make test
Processing /application
Collecting Django>=1.8.5 (from SampleDjangoApp==0.1)
Downloading Django-1.8.5-py2.py3-none-any.whl (6.2MB)
    100% |################################| 6.2MB 112kB/s
Collecting uwsgi>=2.0 (from SampleDjangoApp==0.1)
Downloading uwsgi-2.0.11.2.tar.gz (782kB)
    100% |################################| 782kB 742kB/s
...
...
...
...
Creating test database for alias 'default'...
..........
----------------------------------------------------------------------
Ran 10 tests in 0.045s

OK
Destroying test database for alias 'default'...

real  0m39.394s
user  0m0.315s
sys 0m0.066s

$ time make test
Processing /application
Collecting Django>=1.8.5 (from SampleDjangoApp==0.1)
  Using cached Django-1.8.5-py2.py3-none-any.whl
Collecting uwsgi>=2.0 (from SampleDjangoApp==0.1)
Collecting coverage (from SampleDjangoApp==0.1)
Installing collected packages: Django, uwsgi, coverage, SampleDjangoApp
  Running setup.py install for SampleDjangoApp
Successfully installed Django-1.8.5 SampleDjangoApp-0.1 coverage-4.0.1 uwsgi-2.0.11.2
Creating test database for alias 'default'...
..........
----------------------------------------------------------------------
Ran 10 tests in 0.044s

OK
Destroying test database for alias 'default'...

real  0m5.740s
user  0m0.286s
sys 0m0.019s
```

After testing is successful, application artefacts are built using the `make build` command.  This will output a Python Wheel for the application and each dependency in the `wheelhouse` folder:

```bash
$ make build
Processing /application
Collecting Django>=1.8.5 (from SampleDjangoApp==0.1)
  Using cached Django-1.8.5-py2.py3-none-any.whl
  Saved /wheelhouse/Django-1.8.5-py2.py3-none-any.whl
Collecting uwsgi>=2.0 (from SampleDjangoApp==0.1)
  Saved /wheelhouse/uWSGI-2.0.11.2-py2-none-any.whl
Skipping Django, due to already being wheel.
Skipping uwsgi, due to already being wheel.
Building wheels for collected packages: SampleDjangoApp
  Running setup.py bdist_wheel for SampleDjangoApp
  Stored in directory: /wheelhouse
Successfully built SampleDjangoApp
```

With application artefacts built, the final step is to create a release image using the `make release` command.  

This will create an image based from the base image, ensuring development and test dependencies are not included in production releases:

```bash
$ make release
docker build -t mycompany/myapp:latest .
Sending build context to Docker daemon 7.776 MB
Step 0 : FROM mycompany/myapp-base
 ---> 333bb56f3d69
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Using cache
 ---> 28ddfe42068f
Step 2 : ENV PORT 8000 PROJECT_NAME SampleDjangoApp
 ---> Using cache
 ---> b8c9c94396f8
Step 3 : ADD wheelhouse /wheelhouse
 ---> fe49bee27a1e
Removing intermediate container 3459a4478d82
Step 4 : RUN . /appenv/bin/activate &&     pip install --no-index -f wheelhouse ${PROJECT_NAME} &&     rm -rf /wheelhouse
 ---> Running in 35e96329cb9a
Ignoring indexes: https://pypi.python.org/simple
Collecting SampleDjangoApp
Collecting uwsgi>=2.0 (from SampleDjangoApp)
Collecting Django>=1.8.5 (from SampleDjangoApp)
Installing collected packages: uwsgi, Django, SampleDjangoApp
Successfully installed Django-1.8.5 SampleDjangoApp-0.1 uwsgi-2.0.11.2
 ---> 50ab4766770b
Removing intermediate container 35e96329cb9a
Step 5 : EXPOSE ${PORT}
 ---> Running in f2fb97a491d0
 ---> afb89cb5e94f
Removing intermediate container f2fb97a491d0
Successfully built afb89cb5e94f
```

### Running the Release Image

With release application artefacts and runtime images built, at this point it is possible to establish a sandbox environment with the application release using tools like docker-compose.  With the sandbox environment in place, automated functional/integration tests can be executed as a final gate before publishing the release application artefact and runtime image.  With the various artefacts published, your continuous deployment processes can be triggered to release the application into the appropriate target environments.

> Estalishing a sandbox environment and running functional tests for the sample application will be added in a future version of this project

You can also run arbitrary commands against the created release image, which can be useful.  The following commands can be used for this:

- `make run <cmd>` - creates a container from the release image, runs an arbitrary command and destroys the container
- `make manage <django admin cmd>` - creates a container from the release image, runs a Django admin command and destroys the container

Examples:

```bash
# Get an interactive prompt
$ make run bash
docker run -it --rm -p 8000:8000 mycompany/myapp:latest  bash
root@a584b6cb23a6:/# manage.py check
System check identified no issues (0 silenced).
root@a584b6cb23a6:/# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=127 time=39.0 ms
```

```bash
# Run Django migrations
$ make manage migrate
docker run -it --rm -p 8000:8000 mycompany/myapp:latest manage.py migrate
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
# Run Django collectstatic
$ make -- manage collectstatic --noinput
docker run -it --rm -p 8000:8000 mycompany/myapp:latest manage.py collectstatic --noinput
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/css/base.css'
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/css/rtl.css'
...
63 static files copied to '/var/www/mysite/static'.
```

> Use the `--` separator after the `make` command to allow any subsequent arguments to be passed to the `docker run` command, rather than being interpreted by the `make` command as arguments.

> Currently there are some limitations related to how make works that restrict colons and possibly other special characters being used in the command string passed to `make run` and `make manage`.

## TODO

- Add best practices for Django settings and how to apply different environment settings
- Add automatic versioning
- Add support to publish Python Wheels and Docker Images
- Add sandbox environment (using docker-compose) and functional tests example
- Add CI system example (e.g. using Jenkins or GoCD)
- Add CD workflow 

## Acknowledgements

Inspiration and ideas for this project were drawn from the following sources:

- https://glyph.twistedmatrix.com/2015/03/docker-deploy-double-dutch.html
- http://marmelab.com/blog/2014/09/10/make-docker-command.html
- http://www.itnotes.de/docker/development/tools/2014/08/31/speed-up-your-docker-workflow-with-a-makefile/
- https://hynek.me/articles/virtualenv-lives/

