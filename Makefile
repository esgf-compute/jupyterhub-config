default: help

.PHONY: docker buildkit buildkit-local help

OUTPUT_REGISTRY ?=
IMAGE_NAME ?= $(if $(OUTPUT_REGISTRY),$(OUTPUT_REGISTRY)/)nimbus-basic
IMAGE_TAG ?= $(shell git rev-parse --short HEAD)
BUILD_ARGS ?= build \
							--frontend dockerfile.v0 \
							--local context=. \
							--local dockerfile=. 

IMAGE_OUTPUT ?= --output type=image,name=$(IMAGE_NAME):$(IMAGE_TAG),push=true

LOCAL_EXPORT_CACHE ?= --export-cache type=local,dest=/cache
LOCAL_IMPORT_CACHE ?= --import-cache type=local,src=/cache

REMOTE_EXPORT_CACHE ?= --export-cache type=registry,ref=$(IMAGE_NAME):cache
REMOTE_IMPORT_CACHE ?= --import-cache type=registry,ref=$(IMAGE_NAME):cache

CONDA_BUILD_ARGS ?= build \
										--frontend dockerfile.v0 \
										--local context=. \
										--local dockerfile=$(PWD)/src/esgf_search \
										--opt build-arg:CONDA_USERNAME=$(CONDA_USR) \
										--opt build-arg:CONDA_PASSWORD=$(CODNA_PSW) 

build-conda-pkg: #: Builds esgf-search conda package
	buildctl-daemonless.sh $(CONDA_BUILD_ARGS)

bump-major: #: Bumps the major version
	bump2version --config-file src/esgf_search/.bumpversion.cfg major

bump-minor: #: Bumps the minor version
	bump2version --config-file src/esgf_search/.bumpversion.cfg minor

bump-patch: #: Bumps the patch version
	bump2version --config-file src/esgf_search/.bumpversion.cfg patch

build-container-docker: #: Build notebook image using docker
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

build-container-bk: #: Build notebook image using buildkit in a container
	docker run -it --rm --privileged \
		-v ${PWD}:/src -w /src \
		-v ${PWD}/cache:/cache \
		--entrypoint buildctl-daemonless.sh \
		moby/buildkit:master \
		$(BUILD_ARGS) $(LOCAL_EXPORT_CACHE) $(LOCAL_IMPORT_CACHE)

build-container: #: Build notebook image using buildkit locally
	buildctl-daemonless.sh $(BUILD_ARGS) $(ifeq $(GIT_BRANCH),"master",$(IMAGE_OUTPUT)) $(REMOTE_EXPORT_CACHE) $(REMOTE_IMPORT_CACHE)

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/\1\2/g"
