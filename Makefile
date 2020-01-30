default: help

.PHONY: bump-major bump-minor bump-patch build-jupyterhub build-esgf-search help

IMAGE_NAME = $(if $(OUTPUT_REGISTRY),$(OUTPUT_REGISTRY)/)nimbus-basic
IMAGE_TAG = $(shell git rev-parse --short HEAD)

GIT_BRANCH = $(shell git branch)

ifeq ($(shell which buildctl-daemonless.sh),)
	BUILD = docker run -it --rm --privileged \
					-v $(PWD):/build -w /build \
					-v $(PWD)/cache:/cache \
					-v $(PWD)/output:/output \
					--entrypoint buildctl-daemonless.sh \
					moby/buildkit:master \
					build

	CACHE_ = --export-cache type=local,dest=/cache \
					--import-cache type=local,src=/cache

	TAGGED = --output type=docker,name=$(IMAGE_NAME):latest,dest=/output/$(IMAGE_NAME)
	LATEST = $(TAGGED)
else
	BUILD = buildctl-daemonless.sh \
					build

	CACHE_ = --export-cache type=registry,ref=$(IMAGE_NAME):cache \
					--import-cache type=registry,ref=$(IMAGE_NAME):cache

	TAGGED = --output type=image,name=$(IMAGE_NAME):$(IMAGE_TAG),push=true 
	LATEST = --output type=image,name=$(IMAGE_NAME):latest,push=true
endif

TARGET_ = --opt target=$(TARGET)

CONDA = --opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN)
SEARCH_CONTAINER = --output type=docker,name=esgf-search:latest,dest=/output/esgf-search

bump-major: #: Bumps the major version
	bump2version --config-file src/esgf_search/.bumpversion.cfg major

bump-minor: #: Bumps the minor version
	bump2version --config-file src/esgf_search/.bumpversion.cfg minor

bump-patch: #: Bumps the patch version
	bump2version --config-file src/esgf_search/.bumpversion.cfg patch

build-jupyterhub:
ifeq ($(findstring * master,$(GIT_BRANCH)),)
	$(MAKE) build DOCKERFILE_DIR=. OUTPUT_ARGS="$(TAGGED)" CACHE="$(CACHE_)"
else
	$(MAKE) build DOCKERFILE_DIR=. OUTPUT_ARGS="$(LATEST)" CACHE="$(CACHE_)"
endif

build-search:
	$(MAKE) build DOCKERFILE_DIR=esgf_search/ \
		TARGET="$(TARGET_)" \
		OUTPUT_ARGS="$(SEARCH_CONTAINER)" \
		CACHE="$(CACHE_)" \
		EXTRA="$(CONDA)"

	cat output/esgf-search | docker load

	docker run -it --rm --name esgf-search -p 8080:8080 -v $(PWD)/esgf_search:/build -w /build esgf-search:latest 

build:
	$(BUILD) \
		--frontend dockerfile.v0 \
		--local context=. \
		--local dockerfile=$(DOCKERFILE_DIR) \
		$(EXTRA) \
		$(TARGET) \
		$(OUTPUT_ARGS) \
		$(CACHE)

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/\1\2/g"
