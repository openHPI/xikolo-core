#!/usr/bin/env make -f

CI_COMMIT_SHA ?= $(shell git rev-parse HEAD)
export CI_COMMIT_SHA

CI_REGISTRY_IMAGE ?= registry.xikolo.de/xikolo/web
export CI_REGISTRY_IMAGE

REGISTRY ?= ${CI_REGISTRY_IMAGE}/
export REGISTRY

APPLICATIONS := $(basename $(notdir $(wildcard ./files/*.Dockerfile)))

.PHONY: all
all: info
	docker buildx bake --pull --load default

.PHONY: info
info:
	@echo "CI_COMMIT_SHA:     $(CI_COMMIT_SHA)"
	@echo "CI_REGISTRY_IMAGE: $(CI_REGISTRY_IMAGE)"
	@echo "REGISTRY:          $(REGISTRY)"

.PHONY: $(APPLICATIONS)
$(APPLICATIONS): info
	echo "$(REGISTRY)"
	docker buildx bake --pull --load "$@"
