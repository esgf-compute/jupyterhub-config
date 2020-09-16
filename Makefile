CACHE_PATH := $(PWD)/cache
CACHE_ARGS = --export-cache type=local,dest=$(CACHE_PATH),mode=max \
						 --import-cache type=local,src=$(CACHE_PATH)

OUTPUT_PATH := $(PWD)/output
OUTPUT_REGISTRY := $(if $(REGISTRY),$(REGISTRY)/)
OUTPUT_REGISTRY_ARGS = --output type=image,name=$(OUTPUT_REGISTRY)$(IMAGE_NAME):$(VERSION),push=true
OUTPUT_LOCAL_ARGS = --output type=docker,name=$(OUTPUT_REGISTRY)$(IMAGE_NAME):$(VERSION),dest=$(OUTPUT_PATH)/image.tar
OUTPUT_ARGS = $(if $(REGISTRY),$(OUTPUT_REGISTRY_ARGS),$(OUTPUT_LOCAL_ARGS))

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

POST_BUILD = $(if $(REGISTRY),,cat $(OUTPUT_PATH)/image.tar | docker load)

NIMBUS_BASE_VERSION ?= $(shell cat dockerfiles/nimbus_base/VERSION)
NIMBUS_BASE_CONTAINER := jupyter/base-notebook:lab-2.2.5

.PHONY: build-search
build-search: TARGET = --opt target=publish
build-search: EXTRA = --opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN)
build-search:
	$(BUILD) build.sh dockerfiles/esgf_search $(TARGET) $(CACHE) $(EXTRA)

.PHONY: build-base
build-base: IMAGE_NAME := nimbus-base
build-base: VERSION := $(NIMBUS_BASE_VERSION)
build-base: 
	$(BUILD) build.sh dockerfiles/nimbus_base $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_CONTAINER=$(NIMBUS_BASE_CONTAINER)

	$(POST_BUILD)

.PHONY: build-cdat
build-cdat: IMAGE_NAME := nimbus-cdat
build-cdat: VERSION ?= $(shell cat dockerfiles/nimbus_cdat/VERSION)
build-cdat:
	$(BUILD) build.sh dockerfiles/nimbus_cdat $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_CONTAINER=$(OUTPUT_REGISTRY)nimbus-base:$(NIMBUS_BASE_VERSION)
	
	$(POST_BUILD)

.PHONY: build-dev
build-dev: IMAGE_NAME := nimbus-dev
build-dev: VERSION ?= $(shell cat dockerfiles/nimbus_dev/VERSION)
build-dev:
	$(BUILD) build.sh dockerfiles/nimbus_dev $(CACHE_ARGS) $(OUTPUT_ARGS) \
		--opt build-arg:BASE_CONTAINER=$(OUTPUT_REGISTRY)nimbus-base:$(NIMBUS_BASE_VERSION)

	$(POST_BUILD)
