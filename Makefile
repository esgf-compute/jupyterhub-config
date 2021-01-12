GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

POST_VERSION := $(if $(findstring $(GIT_BRANCH),devel),-dev)

CACHE_PATH := $(PWD)/cache
CACHE_ARGS = --export-cache type=local,dest=$(CACHE_PATH),mode=max \
						 --import-cache type=local,src=$(CACHE_PATH)

OUTPUT_PATH := $(PWD)/output
OUTPUT_IMAGE = $(if $(REGISTRY),$(REGISTRY)/)$(IMAGE_NAME):$(VERSION)$(POST_VERSION)
OUTPUT_REGISTRY_ARGS = --output type=image,name=$(OUTPUT_IMAGE),push=true
OUTPUT_LOCAL_ARGS = --output type=docker,name=$(OUTPUT_IMAGE),dest=$(OUTPUT_PATH)/image.tar
OUTPUT_ARGS = $(if $(findstring true,$(OUTPUT_LOCAL)),$(OUTPUT_LOCAL_ARGS),$(OUTPUT_REGISTRY_ARGS))

ifeq ($(shell which buildctl-daemonless.sh),)
BUILD = docker run \
				-it --rm \
				--privileged \
				-v $(PWD):/build -w /build \
				-v $(CACHE_PATH):$(CACHE_PATH) \
				-v $(OUTPUT_PATH):$(OUTPUT_PATH) \
				-v $(HOME)/.docker:/root/.docker \
				--entrypoint /bin/sh \
				moby/buildkit:master 
else
BUILD = $(SHELL)
endif

POST_BUILD = $(if $(findstring true,$(OUTPUT_LOCAL)),cat $(OUTPUT_PATH)/image.tar | docker load,)

BASE_IMAGE_TAG := lab-2.2.9
BASE_IMAGE := jupyter/base-notebook:$(BASE_IMAGE_TAG)

NIMBUS_BASE_TAG := $(shell cat dockerfiles/nimbus_base/VERSION)
NIMBUS_BASE_IMAGE := nimbus-base
NIMBUS_BASE := $(REGISTRY)/$(NIMBUS_BASE_IMAGE):$(NIMBUS_BASE_TAG)

.PHONY: build-search
build-search:
	$(BUILD) build.sh dockerfiles/esgf_search $(CACHE) \
		--opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN) \
		--opt build-arg:BASE_IMAGE=continuumio/miniconda3:4.7.12

.PHONY: build-base
build-base: IMAGE_NAME := $(NIMBUS_BASE_IMAGE)
build-base: VERSION := $(NIMBUS_BASE_TAG)
build-base: 
	$(BUILD) build.sh dockerfiles/nimbus_base $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE)

	$(POST_BUILD)

.PHONY: build-cdat
build-cdat: IMAGE_NAME := nimbus-cdat
build-cdat: VERSION := $(shell cat dockerfiles/nimbus_cdat/VERSION)
build-cdat:
	$(BUILD) build.sh dockerfiles/nimbus_cdat $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_IMAGE=$(NIMBUS_BASE)
	
	$(POST_BUILD)

.PHONY: build-dev
build-dev: IMAGE_NAME := nimbus-dev
build-dev: VERSION := $(shell cat dockerfiles/nimbus_dev/VERSION)
build-dev:
	$(BUILD) build.sh dockerfiles/nimbus_dev $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_IMAGE=$(NIMBUS_BASE)

	$(POST_BUILD)
