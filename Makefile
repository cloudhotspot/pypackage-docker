include env_make
REPO_NS ?= mycompany
REPO_VERSION ?= latest
IMAGE_NAME ?= myapp
PORTS ?= 8000:8000

.PHONY: image build release run manage clean test agent all env_make start stop

# Extract make image arguments and image context
ifeq (image,$(firstword $(MAKECMDGOALS)))
  IMAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifdef IMAGE_ARGS
  	IMAGE_FILE_PATH := $(firstword $(IMAGE_ARGS))
  	IMAGE_PATH := $(word 2, $(IMAGE_ARGS))
    ifndef IMAGE_PATH
			IMAGE_PATH := .
    endif
    ifneq (release,$(notdir $(IMAGE_FILE_PATH)))
      IMAGE_CONTEXT := -$(notdir $(IMAGE_FILE_PATH))
    endif
  else
  	IMAGE_FILE_PATH := .
  	IMAGE_PATH := .
  endif
  $(eval $(IMAGE_FILE_PATH):;@:)
  $(eval $(IMAGE_PATH):;@:)
  $(eval $(IMAGE_CONTEXT):;@:)
 endif

# Extract run arguments
ifeq (run,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

# Extract manage arguments
ifeq (manage,$(firstword $(MAKECMDGOALS)))
  MANAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(MANAGE_ARGS):;@:)
endif

# Extract test arguments
ifeq (test,$(firstword $(MAKECMDGOALS)))
  TEST_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(TEST_ARGS):;@:)
endif

# Extract build arguments
ifeq (build,$(firstword $(MAKECMDGOALS)))
  BUILD_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  BUILD_CONTEXT := $(firstword $(BUILD_ARGS))
  ifdef BUILD_CONTEXT
  	ifeq (cmd,$(BUILD_CONTEXT))
  		BUILD_CMD = $(wordlist 2,$(words $(BUILD_ARGS)),$(BUILD_ARGS))
  	else
  		BUILD_CMD = pip wheel .[$(BUILD_CONTEXT)]
  	endif 
  endif 
  $(eval $(BUILD_CONTEXT):;@:)
  $(eval $(BUILD_CMD):;@:)
endif

# Extract and format environment variable string, ports, volumes
ifdef ENV_VARS
  EMPTY :=
	SPACE := $(EMPTY) $(EMPTY)
	ENV_VARS_STRING = -e $(subst $(SPACE), -e ,$(ENV_VARS))
endif

ifdef PORTS
	EMPTY :=
	SPACE := $(EMPTY) $(EMPTY)
	PORTS_STRING = -p $(subst $(SPACE), -p ,$(PORTS))
endif

ifdef VOLUMES
	EMPTY :=
	SPACE := $(EMPTY) $(EMPTY)
	VOLUMES_STRING = -v $(subst $(SPACE), -v ,$(VOLUMES))
endif

image:
	docker build -t $(REPO_NS)/$(IMAGE_NAME)$(IMAGE_CONTEXT):$(REPO_VERSION) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)

build:
	docker-compose -p test -f docker/test.yml run --rm builder
	
release:
	@make image docker/release

run:
	docker-compose -p release -f docker/release.yml run --rm --service-ports app $(RUN_ARGS)

start:
	docker-compose -p release -f docker/release.yml up -d

stop:
	docker-compose -p release -f docker/release.yml stop

manage:
	docker-compose -p release -f docker/release.yml run --rm --service-ports app manage.py $(MANAGE_ARGS)
	
clean:
	docker-compose -p test -f docker/test.yml kill
	docker-compose -p test -f docker/test.yml rm -f
	docker-compose -p release -f docker/release.yml kill
	docker-compose -p release -f docker/release.yml rm -f
	rm -rf target

test: 
	docker-compose -p test -f docker/test.yml run --rm agent
	docker-compose -p test -f docker/test.yml run --rm app
	
agent:
	docker-compose -f docker/test.yml run --rm agent

all:
	@make clean
	@make test
	@make build
	@make release