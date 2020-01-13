default: help

.PHONY: bump-major bump-minor bump-patch build-jupyterhub build-esgf-search help

IMAGE_NAME = $(if $(OUTPUT_REGISTRY),$(OUTPUT_REGISTRY)/)nimbus-basic
IMAGE_TAG = $(shell git rev-parse --short HEAD)

TAGGED = --output type=image,name=$(IMAGE_NAME):$(IMAGE_TAG),push=true 
LATEST = --output type=image,name=$(IMAGE_NAME):latest,push=true

bump-major: #: Bumps the major version
	bump2version --config-file src/esgf_search/.bumpversion.cfg major

bump-minor: #: Bumps the minor version
	bump2version --config-file src/esgf_search/.bumpversion.cfg minor

bump-patch: #: Bumps the patch version
	bump2version --config-file src/esgf_search/.bumpversion.cfg patch

build-jupyterhub:
	$(MAKE) build DOCKERFILE_DIR=./ OUTPUT="$(TAGGED)"

ifneq ($(findstring * master,$(shell git branch)),)
	$(MAKE) build DOCKERFILE_DIR=./ OUTPUT="$(LATEST)"
endif

build-esgf-search:
	$(MAKE) build DOCKERFILE_DIR=esgf_search/

build:
ifeq ($(shell which buildctl-daemonless.sh),)
	docker run -it --rm --privileged \
		-v $(PWD):/src -w /src \
		-v $(PWD)/cache:/cache \
		--entrypoint buildctl-daemonless.sh \
		moby/buildkit:master \
		build \
		--frontend dockerfile.v0 \
		--local context=. \
		--local dockerfile=$(DOCKERFILE_DIR) \
		--opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN) \
		--export-cache type=local,dest=/cache \
		--import-cache type=local,src=/cache 
else
	buildctl-daemonless.sh \
		build \
		--frontend dockerfile.v0 \
		--local context=. \
		--local dockerfile=$(DOCKERFILE_DIR) \
		--opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN) \
		$(OUTPUT) \
		--export-cache type=registry,ref=$(IMAGE_NAME):cache \
		--import-cache type=registry,ref=$(IMAGE_NAME):cache
endif

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/\1\2/g"
