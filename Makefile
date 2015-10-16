REPO_NS ?= mycompany
REPO_VERSION ?= latest
IMAGE_NAME ?= myapp
PORTS ?= 8000:8000

.PHONY: image build release run manage clean test probe

# Extract make image arguments and image context
ifeq (image,$(firstword $(MAKECMDGOALS)))
  IMAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifdef IMAGE_ARGS
  	IMAGE_FILE_PATH := $(firstword $(IMAGE_ARGS))
  	IMAGE_PATH := $(word 2, $(IMAGE_ARGS))
    ifndef IMAGE_PATH
			IMAGE_PATH := .
    endif
  	IMAGE_CONTEXT := -$(notdir $(IMAGE_FILE_PATH))
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
	@docker build -t $(REPO_NS)/$(IMAGE_NAME)$(IMAGE_CONTEXT):$(REPO_VERSION) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)

build:
	@if docker inspect $(REPO_NS)-$(IMAGE_NAME)-cache > /dev/null 2>&1; \
	then docker run --rm $(PORTS_STRING) $(ENV_VARS_STRING) $(VOLUMES_STRING) -v "$$(pwd)"/src:/application -v "$$(pwd)"/wheelhouse:/wheelhouse --volumes-from $(REPO_NS)-$(IMAGE_NAME)-cache $(REPO_NS)/$(IMAGE_NAME)-builder:$(REPO_VERSION) $(BUILD_CMD); \
	else docker run --rm $(PORTS_STRING) $(ENV_VARS_STRING) $(VOLUMES_STRING) -v "$$(pwd)"/src:/application -v "$$(pwd)"/wheelhouse:/wheelhouse $(REPO_NS)/$(IMAGE_NAME)-builder:$(REPO_VERSION) $(BUILD_CMD); fi

release:
	@docker build -t $(REPO_NS)/$(IMAGE_NAME):$(REPO_VERSION) .

run:
	@docker run -it --rm $(PORTS_STRING) $(ENV_VARS_STRING) $(VOLUMES_STRING) $(REPO_NS)/$(IMAGE_NAME):$(REPO_VERSION) $(RUN_ARGS)

manage:
	@docker run -it --rm $(PORTS_STRING) $(ENV_VARS_STRING) $(VOLUMES_STRING) $(REPO_NS)/$(IMAGE_NAME):$(REPO_VERSION) manage.py $(MANAGE_ARGS)

clean:
	@rm -rf wheelhouse
	@docker rm $(REPO_NS)-$(IMAGE_NAME)-cache > /dev/null 2>&1 || true
	@docker rmi $(REPO_NS)-$(IMAGE_NAME)-cache > /dev/null 2>&1 || true

test: 
	@if docker inspect $(REPO_NS)-$(IMAGE_NAME)-cache > /dev/null 2>&1; \
  then docker run -it --rm --volumes-from $(REPO_NS)-$(IMAGE_NAME)-cache -v "$$(pwd)"/src:/application $(REPO_NS)/$(IMAGE_NAME)-test:$(REPO_VERSION) $(TEST_ARGS); \
	else docker run -it -v /cache --name $(REPO_NS)-$(IMAGE_NAME)-cache -v "$$(pwd)"/src:/application $(REPO_NS)/$(IMAGE_NAME)-test:$(REPO_VERSION) $(TEST_ARGS); fi

agent:
	docker-compose -f docker/test.yml run --rm agent