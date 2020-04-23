.PHONY: build-search build-jupyterlab b2v-search b2v-jupyterlab

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

CACHE = --export-cache type=local,dest=/cache,mode=max \
				--import-cache type=local,src=/cache

hub-service-configmap:
	kubectl create configmap hub-services \
		--from-file=services/announcement/announcement.py \
		--from-file=services/announcement/page.html \
		--from-file=services/announcement/admin.html \
		--dry-run -oyaml | kubectl apply -f -

b2v-search: PART = patch
b2v-search:
	bump2version --config-file esgf_search/.bumpversion.cfg $(PART)

b2v-jupyterlab: PART = patch
b2v-jupyterlab:
	bump2version --config-file ./.bumpversion.cfg $(PART)

build-search: TARGET = --opt target=publish
build-search: EXTRA = --opt build-arg:CONDA_TOKEN=$(CONDA_TOKEN)
build-search:
	$(BUILD) build.sh dockerfiles/esgf_search $(TARGET) $(CACHE) $(EXTRA)

run-jupyterlab: IMAGE_NAME = $(if $(REGISTRY),$(REGISTRY)/)nimbus-jupyterlab
run-jupyterlab: VERSION = 1.0.3
run-jupyterlab: OUTPUT = --output type=docker,name=$(IMAGE_NAME):$(VERSION),dest=/output/image.tar
run-jupyterlab:
	$(BUILD) build.sh dockerfiles/nimbus_jupyterlab $(CACHE) $(OUTPUT)

	cat output/image.tar | docker load

	docker run -it --rm -p 8888:8888 $(IMAGE_NAME):$(VERSION) jupyter lab --ip 0.0.0.0 --port 8888

build-jupyterlab: IMAGE_NAME = $(if $(REGISTRY),$(REGISTRY)/)nimbus-jupyterlab
build-jupyterlab: VERSION = 1.0.3
build-jupyterlab: OUTPUT = --output type=image,name=$(IMAGE_NAME):$(TAG_PREFIX)$(VERSION)$(TAG_POSTFIX),push=true
build-jupyterlab:
	$(BUILD) build.sh dockerfiles/nimbus_jupyterlab $(CACHE) $(OUTPUT)
