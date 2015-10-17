REPO_NS ?= mycompany
REPO_VERSION ?= latest
IMAGE_NAME ?= myapp

.PHONY: image build release run manage clean test agent all start stop bootstrap

# Helpers
GIT_BRANCH = "git rev-parse --abbrev-ref HEAD"
COMMIT_COUNT = "git rev-list HEAD --count"

# Cosmetices
YELLOW = "\033[1;33m"
NC = "\033[0m"

# Shell Functions
INFO=sh -c '\
  printf $(YELLOW); \
  echo "=> $$1"; \
  printf $(NC)' INFO

# Extract make image arguments and image context
ifeq (image,$(firstword $(MAKECMDGOALS)))
  IMAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifdef IMAGE_ARGS
  	IMAGE_FILE_PATH := $(firstword $(IMAGE_ARGS))
  	IMAGE_PATH := $(word 2, $(IMAGE_ARGS))
    ifndef IMAGE_PATH
			IMAGE_PATH := .
    endif
    # ifneq (release,$(notdir $(IMAGE_FILE_PATH)))
    IMAGE_CONTEXT := $(notdir $(IMAGE_FILE_PATH))
    # else 
    	# IMAGE_CONTEXT := $(GIT_CONTEXT)
    # endif
  else
  	IMAGE_FILE_PATH := .
  	IMAGE_PATH := .
  endif
  $(eval $(IMAGE_FILE_PATH):;@:)
  $(eval $(IMAGE_PATH):;@:)
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

# Expansion
# GIT_CONTEXT := $$(eval $(GIT_BRANCH))
FQ_IMAGE_NAME := $(REPO_NS)/$(IMAGE_NAME)-$(IMAGE_CONTEXT):$(REPO_VERSION)


image:
	@${INFO} "Building Docker image $(FQ_IMAGE_NAME)..."
	@docker build -t $(FQ_IMAGE_NAME) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)
	@${INFO} "Image complete"
build:
	@${INFO} "Building Python wheels..."
	@docker-compose -p test -f docker/test.yml run --rm builder
	@${INFO} "Build complete"

release:
	@make image docker/release

bootstrap:
	@${INFO} "Bootstraping release environment..."
	@${INFO} "Ensuring database is ready..."
	@docker-compose -p release -f docker/release.yml run --rm agent
	@${INFO} "Running migrations..."
	@make manage migrate
	@${INFO} "Creating Django admin user..."
	@make manage createsuperuser
	@${INFO} "Collecting static assets..."
	@make -- manage collectstatic --noinput
	@${INFO} "Bootstrap complete"

run:
	@${INFO} "Running command $(RUN_ARGS)..."
	docker-compose -p release -f docker/release.yml run --rm --service-ports app $(RUN_ARGS)

start:
	@${INFO} "Starting release environment..."
	@docker-compose -p release -f docker/release.yml up -d
	@${INFO} "Release environment started"

stop:
	@${INFO} "Stopping release environment..."
	@docker-compose -p release -f docker/release.yml stop
	@${INFO} "Release environment stopped"

manage:
	@${INFO} "Running python manage.py $(MANAGE_ARGS)..."
	@docker-compose -p release -f docker/release.yml run --rm --service-ports app manage.py $(MANAGE_ARGS)
	
clean:
	@${INFO} "Cleaning test environment..."
	@docker-compose -p test -f docker/test.yml kill
	@docker-compose -p test -f docker/test.yml rm -f
	@${INFO} "Cleaning release environment..."
	@docker-compose -p release -f docker/release.yml kill
	@docker-compose -p release -f docker/release.yml rm -f
	@${INFO} "Cleaning target folder..."
	@rm -rf target
	@${INFO} "Clean complete"

test: 
	@${INFO} "Ensuring database is ready..."
	@docker-compose -p test -f docker/test.yml run --rm agent
	@${INFO} "Running tests..."
	@docker-compose -p test -f docker/test.yml run --rm app
	@${INFO} "Testing complete"

all:
	@make clean
	@make test
	@make build
	@make release
	@make bootstrap
	@make start