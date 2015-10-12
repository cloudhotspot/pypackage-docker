REPO_NS ?= cloudhotspot
REPO_VERSION ?= latest
IMAGE_NAME ?= sampledjangoapp
APP_NAME ?= sampleapp
PORTS ?= 8000:8000

.PHONY: image build release run manage clean test

# Extract make image arguments and image context
ifeq (image,$(firstword $(MAKECMDGOALS)))
  IMAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifdef IMAGE_ARGS
  	IMAGE_FILE_PATH := $(firstword $(IMAGE_ARGS))
  	IMAGE_PATH := $(word 2, $(IMAGE_ARGS))
    ifndef IMAGE_PATH
			IMAGE_PATH := $(IMAGE_FILE_PATH)
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

# Extract and format environment variable string
ifdef ENV_VARS
  EMPTY :=
	SPACE := $(EMPTY) $(EMPTY)
	ENV_VARS_STRING = -e $(subst $(SPACE), -e ,$(ENV_VARS))
endif

image:
	docker build -t $(REPO_NS)/$(IMAGE_NAME)$(IMAGE_CONTEXT):$(REPO_VERSION) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)

build:
	docker run --rm -v "$$(pwd)"/src:/application -v "$$(pwd)"/wheelhouse:/wheelhouse $(REPO_NS)/$(IMAGE_NAME)-builder:$(REPO_VERSION) $(BUILD_CMD)

release:
	docker build -t $(REPO_NS)/$(IMAGE_NAME)-$(APP_NAME):$(REPO_VERSION) .

run:
	docker run -it --rm -p $(PORTS) $(ENV_VARS_STRING) $(REPO_NS)/$(IMAGE_NAME)-$(APP_NAME):$(REPO_VERSION) $(RUN_ARGS)

manage:
	docker run -it --rm -p $(PORTS) $(REPO_NS)/$(IMAGE_NAME)-$(APP_NAME):$(REPO_VERSION) manage.py $(MANAGE_ARGS)

clean:
	rm -rf wheelhouse