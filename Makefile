REPO_NS ?= mycompany
APP_NAME ?= myapp
REPO_VERSION ?= latest
TEST_ENV_NAME ?= $(REPO_NS)$(APP_NAME)test
RELEASE_ENV_NAME ?= $(REPO_NS)$(APP_NAME)release

.PHONY: image build release run manage clean test agent all start stop bootstrap

# Helpers
GIT_BRANCH = git rev-parse --abbrev-ref HEAD
GIT_SHORT_SHA = git rev-parse --short HEAD
COMMIT_COUNT = git rev-list HEAD --count
# GIT_CONTEXT := $$($(GIT_BRANCH))
GIT_TAG := $$($(GIT_SHORT_SHA))

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
    IMAGE_CONTEXT := $(notdir $(IMAGE_FILE_PATH))
  else
  	IMAGE_FILE_PATH := .
  	IMAGE_PATH := .
  	IMAGE_CONTEXT := "release"
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

# Extract release arguments
ifeq (release,$(firstword $(MAKECMDGOALS)))
  RELEASE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RELEASE_ARGS):;@:)
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

# Expansion variables
FQ_APP_NAME = $(REPO_NS)/$(APP_NAME)-$(IMAGE_CONTEXT)

image:
	@${INFO} "Building Docker image $(FQ_APP_NAME):$(GIT_TAG)..."
	@docker build -t $(FQ_APP_NAME):$(GIT_TAG) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)
	@${INFO} "Tagging image as $(REPO_VERSION)..."
	@docker tag -f $(FQ_APP_NAME):$(GIT_TAG) $(FQ_APP_NAME):$(REPO_VERSION)
	@${INFO} "Removing dangling images..."
	@if [ -n "$$(docker images -f "dangling=true" -q)" ]; then docker rmi $$(docker images -f "dangling=true" -q); fi
	@${INFO} "Image complete"

build:
	@${INFO} "Building Python wheels..."
	@docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm builder
	@${INFO} "Build complete"

release:
	@make image docker/release
	@$(foreach tag,$(RELEASE_ARGS), docker tag -f $(REPO_NS)/$(APP_NAME)-release:$(GIT_TAG) $(REPO_NS)/$(APP_NAME)-release:$(tag);)

bootstrap:
	@${INFO} "Bootstraping release environment..."
	@${INFO} "Ensuring database is ready..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm agent
	@${INFO} "Running migrations..."
	@make manage migrate
	@${INFO} "Creating Django admin user..."
	@make manage createsuperuser
	@${INFO} "Collecting static assets..."
	@make -- manage collectstatic --noinput
	@${INFO} "Bootstrap complete"

run:
	@${INFO} "Running command $(RUN_ARGS)..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm --service-ports app $(RUN_ARGS)

start:
	@${INFO} "Starting release environment..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml up -d
	@${INFO} "Release environment started"

stop:
	@${INFO} "Stopping release environment..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml stop
	@${INFO} "Release environment stopped"

manage:
	@${INFO} "Running python manage.py $(MANAGE_ARGS)..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm --service-ports app manage.py $(MANAGE_ARGS)
	
clean:
	@${INFO} "Cleaning test environment..."
	@docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml kill
	@docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml rm -f -v
	@${INFO} "Cleaning release environment..."
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml kill
	@docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml rm -f -v
	@${INFO} "Cleaning dangling images..."
	@if [ -n "$$(docker images -f "dangling=true" -q)" ]; then docker rmi $$(docker images -f "dangling=true" -q); fi
	@${INFO} "Cleaning target folder..."
	@rm -rf target
	@${INFO} "Clean complete"

test: 
	@${INFO} "Ensuring database is ready..."
	@docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm agent
	@${INFO} "Running tests..."
	@docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm app
	@${INFO} "Testing complete"

all:
	@make clean
	@make test
	@make build
	@make release
	@make bootstrap
	@make start