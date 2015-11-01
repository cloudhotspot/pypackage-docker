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
- Create development image
- Create helper images (optional)

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

### Makefile Environment Settings

First, you need to configure your environment either by setting environment variables or by configuring the top portion of the `Makefile`:

```bash 
REPO_NS ?= mycompany
APP_NAME ?= myapp
REPO_VERSION ?= latest
TEST_ENV_NAME ?= $(REPO_NS)$(APP_NAME)test
RELEASE_ENV_NAME ?= $(REPO_NS)$(APP_NAME)release

...
...
```
These settings will determine how the various Docker images and containers that created and used are named.  In general, you only need to modify:

- REPO_NS
- APP_NAME

### Docker Compose Environment Settings

Docker Compose is used to define the following environments for this workflow:

- Development/Test Environment - this is used for the <a href="https://raw.githubusercontent.com/cloudhotspot/pypackage-docker/master/docs/images/ci-workflow.png" target="_blank">unit/integration test and build phases</a>
- Release Environment - this is used for the <a href="https://raw.githubusercontent.com/cloudhotspot/pypackage-docker/master/docs/images/ci-workflow.png" target="_blank">functional test and release phases</a>

A set of docker compose files are including in the `docker` folder of this repository:

- `base.yml` - defines services and settings common to both the test and release environments
- `dev.yml` - defines services and settings for the development/test environment
- `release.yml` - defines services and settings for the release environment

These files are specifically configured for the sample application and must be adapted for your application.

For further information on how to configure the Docker Compose environment settings, refer to the documentation.

### Docker Images

The CI workfow requires the following images to be created or available for your CI workflow:

- Base image
- Development image

> The order of building the above images is important and must be followed from top to bottom.  

In addition to the above, the workflow introduces the concept of a **helper** image, which provides additional functionality specific to the sample application but may be useful for your own workflows.

### Creating the Base Image

Create the base image using the `make image docker/base` command.  

The base image should include any common dependencies/configuration settings to both development/test images and production images.  

The base image includes an entrypoint script `entrypoint.sh` that activates the Python virtual environment and runs any command in the virtual environment.  This entrypoint is inherited by all child images, promoting reusability.

```bash
$ make image docker/base
=> Building Docker image mycompany/myapp-base:56ffcba...
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
=> Removing dangling images...
=> Image complete
make: `docker/base' is up to date.
```

### Creating the Development Image

Create the builder image using the `make image docker/builder` command.  The development image should include all dependencies required for development, test and build purposes.  This image adds the `test.sh` entrypoint script, which activates the virtual environment, installs the application and then runs a command string (by default `python manage.py test`):

> You must ensure the `FROM` directive in `docker/builder/Dockerfile` references the correct base image and version (see Step 0 below):

```bash
$ make image docker/dev
make image docker/dev
=> Building Docker image mycompany/myapp-dev:aa54358...
Sending build context to Docker daemon 4.671 MB
Step 0 : FROM mycompany/myapp-base:latest
 ---> 189a212d6439
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Using cache
 ---> 3f492367a6f6
Step 2 : RUN apt-get install -qy libffi-dev libssl-dev python-dev libmysqlclient-dev
 ---> Using cache
 ---> dab75995db76
Step 3 : RUN . /appenv/bin/activate &&     pip install wheel
 ---> Using cache
 ---> ef510aa5f82a
Step 4 : ENV WHEELHOUSE /wheelhouse PIP_WHEEL_DIR /wheelhouse PIP_FIND_LINKS /wheelhouse XDG_CACHE_HOME /cache
 ---> Using cache
 ---> a44a5ef2f28e
Step 5 : VOLUME /wheelhouse
 ---> Using cache
 ---> 1a7c3a24ac7a
Step 6 : VOLUME /application
 ---> Using cache
 ---> 0a06eb715731
Step 7 : WORKDIR /application
 ---> Using cache
 ---> 459a81d2b166
Step 8 : ADD scripts/test.sh /usr/local/bin/test.sh
 ---> Using cache
 ---> 0e96be69b6b3
Step 9 : RUN chmod +x /usr/local/bin/test.sh
 ---> Using cache
 ---> 9ececed81875
Step 10 : ENTRYPOINT test.sh
 ---> Running in 19ce60284ec2
 ---> 69dd96b1b581
Removing intermediate container 19ce60284ec2
Step 11 : CMD python manage.py test
 ---> Running in 545a1f427287
 ---> f8b528d4dee5
Removing intermediate container 545a1f427287
Successfully built f8b528d4dee5
=> Tagging image as latest...
=> Removing dangling images...
Deleted: 40af76fef075247beef9fe513613e76575e4710db32fd2e5a6af713b0142773d
=> Image complete
make: `docker/dev' is up to date.
```

### Creating the Helper Image (Optional)

A helper image referred to as an *agent image* is included in this workflow but note that this is specific to the sample application.  The agent image runs an Ansible playbook (defined in `ansible/agent/site.yml`) that is used to allow the MySQL database container time to properly start up when bringing up the environments used in the workflow.  Of course you are free to take whatever approach you like to achieve this goal, this approach is just one of many possible solutions to this problem.

You can create the agent image using the `make image docker/agent` command.  

This image has Ansible installed and `ansible-playbook` defined as its entrypoint.  By supplying the agent container with a playbook file and appropriate command string referencing the file, this image provides an easy mechanism to invoke an arbitrary Ansible playbook within the test or release environments in this workflow.

```bash
$ make image docker/agent
=> Building Docker image mycompany/myapp-agent:56ffcba...
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
=> Removing dangling images...
=> Image complete
make: `docker/agent' is up to date.
```

## Continuous Integration Workflow

With the application, environment and base/builder/test images in place, the continuous integration workflow can be executed.  This workflow would typically be invoked on each application source code commit in a production continuous integration system.  

However it is possible to complete the steps described below manually on a development machine as required.

> The `make all` command provides a one-shot command to clean the environments, execute the workflow and then bootstrap and activate the release environment.

On each commit, the continuous integration workflow starts by running tests inside the test container using the `make test` command.  

This will install the application and run `python manage.py test` in a container based upon the test image:

> The Docker Compose environments include a volume container that stores the pip cache on the Docker host in `/tmp/`.  This allows subsequent invocations of `make test` and `make build` to use cached dependencies for much faster execution times (see example below where the first run of `make test` takes 36 seconds, whilst the second run takes just under 9 seconds). 

```bash
$ time make test
=> Ensuring database is ready...
Creating mycompanymyapptest_db_1...
...
...
=> Running tests...
Creating mycompanymyapptest_cache_1...
Processing /application
...
...
Creating test database for alias 'default'...
..........
----------------------------------------------------------------------
Ran 10 tests in 0.066s

OK
Destroying test database for alias 'default'...
=> Testing complete

real  0m36.645s
user  0m0.674s
sys 0m0.201s

$ time make test
=> Ensuring database is ready...
...
=> Running tests...
Processing /application
Collecting Django>=1.8.5 (from SampleDjangoApp==0.1)
  Using cached Django-1.8.5-py2.py3-none-any.whl
...
...
Creating test database for alias 'default'...
..........
----------------------------------------------------------------------
Ran 10 tests in 0.044s

OK
Destroying test database for alias 'default'...

real  0m7.826s
user  0m0.476s
sys 0m0.130s
```

After testing is successful, application artefacts are built using the `make build` command.  This invokes a builder container defined in the `dev.yml` Docker Compose file:

```yaml
...
...
builder:
  image: mycompany/myapp-dev:latest
  volumes:
    - ../src:/application
    - ../target:/wheelhouse
  volumes_from:
    - cache
  entrypoint: "entrypoint.sh"
  command: ["pip", "wheel", "."]
```

> Notice how the builder container overrides the default entrypoint and command string for the development image.  This illustrates the flexibility of Docker images.

The build process will output a Python Wheel for the application and each dependency in the `/wheelhouse` folder on the container, which is mapped to the `target` folder on the Docker host (this mapping can be changed in the Docker Compose environment settings):

```bash
$ make build
=> Building Python wheels...
Processing /application
Collecting Django>=1.8.5 (from SampleDjangoApp==0.1)
  Using cached Django-1.8.5-py2.py3-none-any.whl
  Saved /wheelhouse/Django-1.8.5-py2.py3-none-any.whl
Collecting uwsgi>=2.0 (from SampleDjangoApp==0.1)
  Saved /wheelhouse/uWSGI-2.0.11.2-py2-none-any.whl
Collecting mysql-python (from SampleDjangoApp==0.1)
  Saved /wheelhouse/MySQL_python-1.2.5-cp27-none-linux_x86_64.whl
Skipping Django, due to already being wheel.
Skipping uwsgi, due to already being wheel.
Skipping mysql-python, due to already being wheel.
Building wheels for collected packages: SampleDjangoApp
  Running setup.py bdist_wheel for SampleDjangoApp
  Stored in directory: /wheelhouse
Successfully built SampleDjangoApp
=> Build complete
```

With application artefacts built, the final step is to create a release image using the `make release` command.  

This will create an image based from the base image, ensuring development and test dependencies are not included in production releases.  The release image is tagged with the current Git commit short SHA hash and also tagged with the value of the REPO_VERSION environment variable (set to latest by default). 

```bash
$ make release
=> Building Docker image mycompany/myapp-release:56ffcba...
Sending build context to Docker daemon 15.33 MB
Step 0 : FROM mycompany/myapp-base
 ---> 56380f292315
Step 1 : MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>
 ---> Using cache
 ---> 8f3898ac6d14
Step 2 : ENV PORT 8000 PROJECT_NAME SampleDjangoApp
 ---> Using cache
 ---> 55a5b15e6955
Step 3 : ADD target /wheelhouse
 ---> Using cache
 ---> b2860b70ef41
Step 4 : RUN . /appenv/bin/activate &&     pip install --no-index -f wheelhouse ${PROJECT_NAME} &&     rm -rf /wheelhouse
 ---> Using cache
 ---> d5f51f7a5be5
Step 5 : EXPOSE ${PORT}
 ---> Using cache
 ---> 424d2ba7bb37
Successfully built 424d2ba7bb37
=> Tagging image as latest...
=> Removing dangling images...
=> Image complete
make[1]: `docker/release' is up to date.
```

### Running the Release Environment

With release application artefacts and runtime images built, at this point it is possible to establish a sandbox environment with the application release using tools like docker-compose.  With the sandbox environment in place, automated functional/integration tests can be executed as a final gate before publishing the release application artefact and runtime image.  With the various artefacts published, your continuous deployment processes can be triggered to release the application into the appropriate target environments.

This project includes a `make bootstrap` command that performs the following tasks specific to the sample application:

- Bring up release environment database and ensure it is ready
- Runs Django migrations
- Creates Django admin super user
- Collects Django static files

With the release environment bootstrapped, you can run `make start` which will start the release environment in a ready to run state.  Similarly you can use `make stop` to stop the release environment without destroying it.

You can also run arbitrary commands against the created release image, which can be useful.  The following commands can be used for this:

- `make run <cmd>` - creates a container from the release image, runs an arbitrary command and destroys the container
- `make manage <django admin cmd>` - creates a container from the release image, runs a Django admin command and destroys the container

Examples:

```bash
$ make bootstrap
=> Bootstraping release environment...
=> Ensuring database is ready...
Creating mycompanymyapprelease_db_1...
...
...
TASK: [Message] ***************************************************************
ok: [localhost] => {
    "msg": "Probing db:3306 with delay=0s and timeout=180s"
}

TASK: [Waiting for host to respond...] ****************************************
ok: [localhost -> 127.0.0.1]
...
...
=> Running migrations...
=> Running python manage.py migrate...
Creating mycompanymyapprelease_static_1...
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
=> Creating Django admin user...
=> Running python manage.py createsuperuser...
Username (leave blank to use 'root'): admin
Email address: admin@example.com
Password: ********
Password (again): ********
Superuser created successfully.
=> Collecting static assets...
=> Running python manage.py collectstatic --noinput...
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/js/urlify.js'
Copying '/appenv/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/js/SelectBox.js'
...
...

63 static files copied to '/var/www/mysite/static'.
=> Bootstrap complete

$ make start
=> Starting release environment...
mycompanymyapprelease_db_1 is up-to-date
Starting mycompanymyapprelease_static_1...
Creating mycompanymyapprelease_app_1...
Creating mycompanymyapprelease_agent_1...
=> Release environment started
```

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

- Add automatic versioning
- Add support to publish Python Wheels and Docker Images
- Add functional tests example
- Add CI system example (e.g. using Jenkins or GoCD)
- Add CD workflow 
- Add support for Git branching (awaiting Docker Compose 1.5 variable substitution features)

## Acknowledgements

Inspiration and ideas for this project were drawn from the following sources:

- https://glyph.twistedmatrix.com/2015/03/docker-deploy-double-dutch.html
- http://marmelab.com/blog/2014/09/10/make-docker-command.html
- http://www.itnotes.de/docker/development/tools/2014/08/31/speed-up-your-docker-workflow-with-a-makefile/
- https://hynek.me/articles/virtualenv-lives/

