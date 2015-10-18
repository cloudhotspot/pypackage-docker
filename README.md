# Python Packager

A methodology for continuous integration and packaging of Python and Django applications using <a href="http://wheel.readthedocs.org/en/latest/" target="_blank">Python Wheels</a> and <a href="https://www.docker.com" target="_blank">Docker</a>. 

Full documentation is provided at <a href="http://pypackage-docker.readthedocs.org">read the docs</a>.  

The goals of this methodology include:

- Portable workflow - you should be able to run this workflow locally on a developer machine or on a CI system like Jenkins.
- Create a Python virtual environment (even inside containers, <a href="https://hynek.me/articles/virtualenv-lives/" target="_blank">see why here</a>).
- Create deployable **native** application artefacts (i.e. Python Wheels, not archives or operating system packages).
- Create deployable runtime environment artefacts (i.e. Docker images). 
- Create simple to maintain manifests that describe application and runtime environment dependencies.
- Eliminate development and test dependencies from production runtime environment artefacts.
- Fast developer feedback - accelerate testing and build activities through Python Wheels caching.
- Ease of use - reduce complexity of running long Docker commands and orchestrating workflows to simple `make` style commands.
- Reusability - use Docker image layering to build dependency and configuration trees that promote reusability
- Leverage familiar Python tooling - use of `pip` and `virtualenv` makes it possible to extract this workflow outside of Docker

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
- Create test environment and run unit/integration tests
- Build application artefacts (i.e. Python wheels)
- Build runtime environment artefacts (i.e. Docker images)
- Deploy release environment for the full application stack (e.g. including databases, caches)
- Run functional tests against release environment
- Publish application and runtime environment artefacts 

This project demonstrates the workflow outlined above, providing the ability to execute each step on any Linux/OS X machine running a Docker client with access to a Docker host.  This workflow can also be automated within a CI system such as Jenkins, triggered by a commit to the source code repository for the application.

The rest of this document provides an example to enable you to get started, and assumes you are using the included sample application located in the `src` folder.  For further information on how to prepare your application for this workflow, refer to the <a href="http://pypackage-docker.readthedocs.org/en/latest/application_requirements.html" target="_blank">documentation</a>.

## Prerequisites

- Linux/OS X computer
- Docker client - the workflow has been tested on Docker 1.8
- Docker Compose - the workflow has been tested on docker-compose 1.4.2
- Docker daemon (either running locally, on local VM or on a remote host)
- Docker daemon must have Internet connectivity
- Docker Machine (Recommended) - if testing on locally OS X, Docker Machine along with your favourite virualisation software is recommended

## Initial Setup

First, you need to configure your environment either by setting environment variables or by configuring the top portion of the `Makefile`:

```bash 
REPO_NS ?= mycompany
REPO_VERSION ?= latest
IMAGE_NAME ?= myapp

.PHONY: image build release run manage clean test
...
...
```
These settings will determine how the various Docker images you create and use are named.

Next you need to ensure the following images are created or available for your CI workflow:

- Base image
- Builder image
- Test image

> The order of building the above images is important and must be followed from top to bottom.  

In addition to the above, this workflow introduces the concept of an **Agent** image, which is specific to the sample application but may be useful for your own workflows.

### Creating the Base Image

Create the base image using the `make image docker/base` command.  

The base image should include any common dependencies/configuration settings to both development/test images and production images.  

The base image includes an entrypoint script `entrypoint.sh` that activates the Python virtual environment and runs any command in the virtual environment.  This entrypoint is inherited by all child images, promoting reusability.

```bash
$ make image docker/base
=> Building Docker image mycompany/myapp-base:latest...
Sending build context to Docker daemon 4.489 MB
Step 0 : FROM ubuntu:trusty
 ---> a005e6b7dd01
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Running in 32f1743c9b29
 ---> 161672d57fb4
Removing intermediate container 32f1743c9b29
Step 2 : RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list &&     apt-get update &&     apt-get install -qyy -o APT::Install-Recommends=false -o APT::Install-Suggests=false python-virtualenv python libffi6 openssl libpython2.7 python-mysqldb
 ---> Running in 73b330b7ea01
...
...
Step 3 : RUN virtualenv /appenv &&     . /appenv/bin/activate &&     pip install pip==7.1.2
 ---> Running in 8bb6b81eb600
New python executable in /appenv/bin/python
Installing setuptools, pip...done.
Downloading/unpacking pip==7.1.2
Installing collected packages: pip
  Found existing installation: pip 1.5.4
    Uninstalling pip:
      Successfully uninstalled pip
Successfully installed pip
Cleaning up...
 ---> 269c64f8032c
Removing intermediate container 8bb6b81eb600
Step 4 : ADD scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
 ---> 6f9432cbfbdd
Removing intermediate container 0ac482760d6e
Step 5 : RUN chmod +x /usr/local/bin/entrypoint.sh
 ---> Running in b007759635ba
 ---> 8b22b92fc5a9
Removing intermediate container b007759635ba
Step 6 : ENTRYPOINT entrypoint.sh
 ---> Running in c768ff3cf1d8
 ---> 0c5087e1533d
Removing intermediate container c768ff3cf1d8
Successfully built 0c5087e1533d
=> Image complete
make: `docker/base' is up to date.
```

### Creating the Builder Image

Create the builder image using the `make image docker/builder` command.  The builder image should include all dependencies required for development and build purposes.

> You must ensure the `FROM` directive in `docker/builder/Dockerfile` references the correct base image and version (see Step 0 below):

```bash
$ make image docker/builder
=> Building Docker image mycompany/myapp-builder:latest...
Sending build context to Docker daemon  4.49 MB
Step 0 : FROM mycompany/myapp-base:latest
 ---> 0c5087e1533d
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Running in f13dfbd9b9aa
 ---> b76137345d77
Removing intermediate container f13dfbd9b9aa
Step 2 : RUN apt-get install -qy libffi-dev libssl-dev python-dev libmysqlclient-dev &&     . /appenv/bin/activate &&     pip install wheel
 ---> Running in 3bbd791ee3cc
...
...
Step 3 : ENV WHEELHOUSE /wheelhouse PIP_WHEEL_DIR /wheelhouse PIP_FIND_LINKS /wheelhouse XDG_CACHE_HOME /cache
 ---> Running in 2787c27adcf4
 ---> 73a387a9ab98
Removing intermediate container 2787c27adcf4
Step 4 : VOLUME /wheelhouse
 ---> Running in 142d7171c70c
 ---> e5589b5a6339
Removing intermediate container 142d7171c70c
Step 5 : VOLUME /application
 ---> Running in 0923b00dd803
 ---> c5e9f04e5ad2
Removing intermediate container 0923b00dd803
Step 6 : WORKDIR /application
 ---> Running in cc671e27723a
 ---> dcbd0d9acf0a
Removing intermediate container cc671e27723a
Step 7 : CMD pip wheel .
 ---> Running in bd76e2da381b
 ---> 02e733c48dcd
Removing intermediate container bd76e2da381b
Successfully built 02e733c48dcd
=> Image complete
make: `docker/builder' is up to date.
```

Create the test image using the `make image docker/test` command.  The test image should include any test dependencies and uses the `test.sh` entrypoint script, which activates the virtual environment, installs the application and then runs a command string (by default `python manage.py test`):

```bash
$ make image docker/test
=> Building Docker image mycompany/myapp-test:latest...
Sending build context to Docker daemon 4.491 MB
Step 0 : FROM mycompany/myapp-builder
 ---> 02e733c48dcd
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Running in 78c61c63517a
 ---> f09bb690d2dd
Removing intermediate container 78c61c63517a
Step 2 : ADD scripts/test.sh /usr/local/bin/test.sh
 ---> 0ae8dcde4e6a
Removing intermediate container 76bce404d127
Step 3 : RUN chmod +x /usr/local/bin/test.sh
 ---> Running in 97238cfa4343
 ---> e571e9f00678
Removing intermediate container 97238cfa4343
Step 4 : ENTRYPOINT test.sh
 ---> Running in 4cd10823b079
 ---> 3cc6233f617d
Removing intermediate container 4cd10823b079
Step 5 : CMD python manage.py test
 ---> Running in 9d0dce419773
 ---> 4b1bfe32fa02
Removing intermediate container 9d0dce419773
Successfully built 4b1bfe32fa02
=> Image complete
make: `docker/test' is up to date.
```
### Creating the Agent Image (Optional)

The agent image is specific to the sample application included in this workflow.  The agent container runs an Ansible playbook (defined in `ansible/agent/site.yml`) that is used to allow the MySQL database container time to properly start up when bringing up the environments used in the workflow.  Of course you are free to take whatever approach you like to achieve this goal, this approach is just one of many possible solutions to this problem.

Create the agent image using the `make image docker/agent` command.  

This image has Ansible installed and `ansible-playbook` defined as its entrypoint.  By supplying the agent container with a playbook file and appropriate command string referencing the file, this image provides an easy mechanism to invoke an arbitrary Ansible playbook within the test or release environments in this workflow.

```bash
$ make image docker/agent
=> Building Docker image mycompany/myapp-agent:latest...
Sending build context to Docker daemon 4.492 MB
Step 0 : FROM ubuntu:trusty
 ---> a005e6b7dd01
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Using cache
 ---> 161672d57fb4
Step 2 : RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list &&     apt-get update -qy &&     apt-get install -qy software-properties-common &&     apt-add-repository -y ppa:ansible/ansible &&     apt-get update -qy &&     apt-get install -qy ansible
 ---> Running in 879fa3c9923f
...
...
Step 3 : VOLUME /ansible
 ---> Running in 4548ca97e3b0
 ---> c5423b6ca790
Removing intermediate container 4548ca97e3b0
Step 4 : WORKDIR /ansible
 ---> Running in 81ebf5b96c2f
 ---> 67e7dde7c4c5
Removing intermediate container 81ebf5b96c2f
Step 5 : ENTRYPOINT ansible-playbook
 ---> Running in dfb2d85663ca
 ---> 68bb8a312b7b
Removing intermediate container dfb2d85663ca
Successfully built 68bb8a312b7b
=> Image complete
make: `docker/agent' is up to date.
```

## Continuous Integration Workflow

With the application, environment and base/builder/test images in place, the continuous integration workflow can be executed.  This workflow would typically be invoked on each application source code commit in a production continuous integration system.  

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
- Add support for Git branching (awaiting Docker Compose 1.5 variable substitution features)

## Acknowledgements

Inspiration and ideas for this project were drawn from the following sources:

- https://glyph.twistedmatrix.com/2015/03/docker-deploy-double-dutch.html
- http://marmelab.com/blog/2014/09/10/make-docker-command.html
- http://www.itnotes.de/docker/development/tools/2014/08/31/speed-up-your-docker-workflow-with-a-makefile/
- https://hynek.me/articles/virtualenv-lives/

