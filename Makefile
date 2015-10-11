NS ?= cloudhotspot
VERSION ?= latest
REPO_PREFIX ?= pypackage
APP_NAME ?= sampleapp
PORTS ?= 8000:8000

.PHONY: image build release run manage clean

# If the first argument is "composer"...
ifeq (image,$(firstword $(MAKECMDGOALS)))
    IMAGE_ARGS := $(firstword $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
    IMAGE_CONTEXT := $(notdir $(IMAGE_ARGS))
    $(eval $(IMAGE_ARGS):;@:)
endif

ifeq (run,$(firstword $(MAKECMDGOALS)))
    RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(RUN_ARGS):;@:)
endif

ifeq (manage,$(firstword $(MAKECMDGOALS)))
    MANAGE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(MANAGE_ARGS):;@:)
endif

ifeq (build,$(firstword $(MAKECMDGOALS)))
    BUILD_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(BUILD_ARGS):;@:)
endif

image:
	docker build -t $(NS)/$(REPO_PREFIX)-$(IMAGE_CONTEXT):$(VERSION) -f $(IMAGE_ARGS)/Dockerfile $(IMAGE_ARGS)

build:
	docker run --rm -v "$$(pwd)"/src:/application -v "$$(pwd)"/wheelhouse:/wheelhouse $(NS)/$(REPO_PREFIX)-builder:$(VERSION) $(BUILD_ARGS)

release:
	docker build -t $(NS)/$(REPO_PREFIX)-$(APP_NAME):$(VERSION) .

run:
	docker run -it --rm -p $(PORTS) $(NS)/$(REPO_PREFIX)-$(APP_NAME):$(VERSION) $(RUN_ARGS)

manage:
	docker run -it --rm -p $(PORTS) $(NS)/$(REPO_PREFIX)-$(APP_NAME):$(VERSION) manage.py $(MANAGE_ARGS)

clean:
	rm -rf wheelhouse