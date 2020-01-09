default: help

.PHONY: docker buildkit buildkit-local help

DOCKER_REGISTRY ?=
IMAGE_NAME ?= $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY)/)nimbus-basic
IMAGE_TAG ?= $(shell git rev-parse --short HEAD)
BUILD_ARGS ?= build \
							--frontend dockerfile.v0 \
							--local context=. \
							--local dockerfile=. 

IMAGE_OUTPUT ?= --output type=image,name=$(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG),push=true

LOCAL_EXPORT_CACHE ?= --export-cache type=local,dest=/cache
LOCAL_IMPORT_CACHE ?= --import-cache type=local,src=/cache

REMOTE_EXPORT_CACHE ?= --export-cache type=registry,ref=$(DOCKER_REGISTRY)/$(IMAGE_NAME):cache
REMOTE_IMPORT_CACHE ?= --import-cache type=registry,ref=$(DOCKER_REGISTRY)/$(IMAGE_NAME):cache

search-build: search-bump-patch #: Builds esgf-search conda package
	docker run -it --rm --privileged \
		-v ${PWD}:/src -w /src \
		-v ${PWD}/cache:/cache \
		--entrypoint buildctl-daemonless.sh \
		moby/buildkit:master \
		build --frontend dockerfile.v0 --local context=. --local dockerfile=/src/src/esgf_search \
		--opt build-arg:CONDA_USERNAME=$(CONDA_USR) \
		--opt build-arg:CONDA_PASSWORD=$(CONDA_PSW) \
		--export-cache type=local,dest=/cache \
		--import-cache type=local,src=/cache

search-bump-major: #: Bumps the major version
	bump2version --config-file src/esgf_search/.bumpversion.cfg major

search-bump-minor: #: Bumps the minor version
	bump2version --config-file src/esgf_search/.bumpversion.cfg minor

search-bump-patch: #: Bumps the patch version
	bump2version --config-file src/esgf_search/.bumpversion.cfg patch

docker: #: Build image using docker
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

buildkit: #: Build image using buildkit in a container
	docker run -it --rm --privileged \
		-v ${PWD}:/src -w /src \
		-v ${PWD}/cache:/cache \
		--entrypoint buildctl-daemonless.sh \
		moby/buildkit:master \
		$(BUILD_ARGS) $(LOCAL_EXPORT_CACHE) $(LOCAL_IMPORT_CACHE)

buildkit-local: #: Build image using buildkit locally
	buildctl-daemonless.sh $(BUILD_ARGS) $(REMOTE_EXPORT_CACHE) $(REMOTE_IMPORT_CACHE)

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g"
