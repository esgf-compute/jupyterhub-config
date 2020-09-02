.PHONY: build-search build-jupyterlab build-dev

ifeq ($(shell which buildctl-daemonless.sh),)
BUILD = docker run \
				-it --rm \
				--privileged \
				-v $(PWD):/build -w /build \
				-v $(PWD)/cache:/cache \
				-v $(PWD)/output:/output \
				-v $(HOME)/.docker:/root/.docker \
				--entrypoint /bin/sh \
				moby/buildkit:master 
else
BUILD = $(SHELL)
endif

CACHE_PATH = $(PWD)/cache
OUTPUT_PATH = $(PWD)/output

CACHE = --export-cache type=local,dest=$(CACHE_PATH),mode=max \
				--import-cache type=local,src=$(CACHE_PATH)

OUTPUT_REGISTRY = --output type=image,name=$(IMAGE_NAME):$(VERSION),push=true
OUTPUT_LOCAL = --output type=docker,name=$(IMAGE_NAME):$(VERSION),dest=/output/image.tar

OUTPUT = $(if $(REGISTRY),$(OUTPUT_REGISTRY),$(OUTPUT_LOCAL))

EXTRA = $(if $(REGISTRY),,cat $(PWD)/output/image.tar | docker load)

build-search: TARGET = --opt target=publish
build-search: EXTRA = --opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN)
build-search:
	$(BUILD) build.sh dockerfiles/esgf_search $(TARGET) $(CACHE) $(EXTRA)

build-jupyterlab: IMAGE_NAME := $(if $(REGISTRY),$(REGISTRY)/)nimbus-jupyterlab
build-jupyterlab: VERSION ?= $(shell cat dockerfiles/nimbus_jupyterlab/VERSION)
build-jupyterlab:
	$(BUILD) build.sh dockerfiles/nimbus_jupyterlab $(CACHE) $(OUTPUT) $(BUILD_EXTRA)
	
	$(EXTRA)

build-dev: IMAGE_NAME := $(if $(REGISTRY),$(REGISTRY)/)nimbus-dev
build-dev: VERSION ?= $(shell cat dockerfiles/nimbus_dev/VERSION)
build-dev:
	$(BUILD) build.sh dockerfiles/nimbus_dev $(CACHE) $(OUTPUT) $(BUILD_EXTRA)
	
	$(EXTRA)
