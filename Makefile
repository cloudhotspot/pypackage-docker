REPO_NS ?= mycompany
APP_NAME ?= myapp
REPO_VERSION ?= latest
TEST_ENV_NAME ?= $(REPO_NS)$(APP_NAME)test
RELEASE_ENV_NAME ?= $(REPO_NS)$(APP_NAME)release

.PHONY: image build release run manage clean test agent all start stop bootstrap remove logs

include make/functions

image:
	${INFO} "Building Docker image $(FQ_APP_NAME):$(GIT_TAG)..."
	@ docker build -t $(FQ_APP_NAME):$(GIT_TAG) -f $(IMAGE_FILE_PATH)/Dockerfile $(IMAGE_PATH)
	${INFO} "Tagging image as $(REPO_VERSION)..."
	@ docker tag -f $(FQ_APP_NAME):$(GIT_TAG) $(FQ_APP_NAME):$(REPO_VERSION)
	${INFO} "Removing dangling images..."
	@ docker images -q --filter "dangling=true" | xargs -I ARGS docker rmi ARGS
	${INFO} "Image complete"

build:
	${INFO} "Building Python wheels..."
	@ docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm builder
	${INFO} "Build complete"

release:
	@ make image docker/release
	@ $(foreach tag,$(RELEASE_ARGS), docker tag -f $(REPO_NS)/$(APP_NAME)-release:$(GIT_TAG) $(REPO_NS)/$(APP_NAME)-release:$(tag);)

bootstrap:
	${INFO} "Bootstraping release environment..."
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm agent
	${INFO} "Running migrations..."
	@ make manage migrate
	${INFO} "Creating Django admin user..."
	@ make manage createsuperuser
	${INFO} "Collecting static assets..."
	@ make -- manage collectstatic --noinput
	${INFO} "Bootstrap complete"

run:
	${INFO} "Running command $(RUN_ARGS)..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm --service-ports app $(RUN_ARGS)

start:
	${INFO} "Starting release environment..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml up -d $(START_ARGS)
	${INFO} "Release environment started"

stop:
	${INFO} "Stopping release environment..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml stop $(STOP_ARGS)
	${INFO} "Release environment stopped"

remove:
	${INFO} "Killing and removing release environment..."
	@ make stop
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml rm -f -v
	${INFO} "Release environment removed"

manage:
	${INFO} "Running python manage.py $(MANAGE_ARGS)..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml run --rm --service-ports app manage.py $(MANAGE_ARGS)

logs:
	${INFO} "Showing logs..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/test.yml logs $(LOGS_ARGS)
	
clean:
	${INFO} "Cleaning test environment..."
	@ docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml kill
	@ docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml rm -f -v
	${INFO} "Cleaning release environment..."
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml kill
	@ docker-compose -p $(RELEASE_ENV_NAME) -f docker/release.yml rm -f -v
	${INFO} "Cleaning dangling images..."
	@ docker images -q --filter "dangling=true" | xargs docker rmi
	${INFO} "Cleaning target folder..."
	@ rm -rf target
	${INFO} "Clean complete"

test: 
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(TEST_ENV_NAME) -f docker/test.yml run --rm app
	${INFO} "Testing complete"

all:
	@ make clean
	@ make test
	@ make build
	@ make release
	@ make bootstrap
	@ make start