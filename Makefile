SHELL := /bin/bash # Use bash syntax

# if not run in travis, get docker_login and _pwd from file
ifndef TRAVIS
	docker_repo := zokradonh
	docker_login := $(shell cat ~/.docker-account-user)
	docker_pwd := $(shell cat ~/.docker-account-pwd)
endif

base_download_version := $(shell ./version.sh core)
core_download_version := $(shell ./version.sh core)
meet_download_version := $(shell ./version.sh meet)
webapp_download_version := $(shell ./version.sh webapp)
zpush_download_version := $(shell ./version.sh zpush)
vcf_ref := $(shell git rev-parse --short HEAD)

KOPANO_CORE_REPOSITORY_URL := file:/kopano/repo/core
KOPANO_MEET_REPOSITORY_URL := file:/kopano/repo/meet
KOPANO_WEBAPP_REPOSITORY_URL := file:/kopano/repo/webapp
KOPANO_WEBAPP_FILES_REPOSITORY_URL := file:/kopano/repo/files
KOPANO_WEBAPP_MDM_REPOSITORY_URL := file:/kopano/repo/mdm
KOPANO_WEBAPP_SMIME_REPOSITORY_URL := file:/kopano/repo/smime
KOPANO_ZPUSH_REPOSITORY_URL := http://repo.z-hub.io/z-push:/final/Debian_9.0/
RELEASE_KEY_DOWNLOAD := 0
DOWNLOAD_COMMUNITY_PACKAGES := 1

DOCKERCOMPOSE_FILE := docker-compose.yml
TAG_FILE := build.tags
-include .env
export

# convert lowercase componentname to uppercase
COMPONENT = $(shell echo $(component) | tr a-z A-Z)

.PHONY: default
default: help

.PHONY: help
help:
	@eval $$(sed -r -n 's/^([a-zA-Z0-9_-]+):.*?## (.*)$$/printf "\\033[36m%-30s\\033[0m %s\\n" "\1" "\2" ;/; ta; b; :a p' $(MAKEFILE_LIST) | sort)

.PHONY: build-all
all: build-all

build-all:
	make $(shell grep -o ^build-.*: Makefile | grep -Ev 'build-all|build-simple|build-builder|build-webapp-demo' | uniq | sed s/://g | xargs)

.PHONY: build
build: component ?= base
build: ## Helper target to build a given image. Defaults to the "base" image.
ifdef TRAVIS
	@echo "fetching previous build to warm up build cache (only on travis)"
	docker pull  $(docker_repo)/kopano_$(component):builder || true
endif
	docker build \
		--build-arg VCS_REF=$(vcf_ref) \
		--build-arg docker_repo=${docker_repo} \
		--build-arg KOPANO_CORE_VERSION=${core_download_version} \
		--build-arg KOPANO_$(COMPONENT)_VERSION=${$(component)_download_version} \
		--build-arg KOPANO_CORE_REPOSITORY_URL=$(KOPANO_CORE_REPOSITORY_URL) \
		--build-arg KOPANO_MEET_REPOSITORY_URL=$(KOPANO_MEET_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_REPOSITORY_URL=$(KOPANO_WEBAPP_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_FILES_REPOSITORY_URL=$(KOPANO_WEBAPP_FILES_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_MDM_REPOSITORY_URL=$(KOPANO_WEBAPP_MDM_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_SMIME_REPOSITORY_URL=$(KOPANO_WEBAPP_SMIME_REPOSITORY_URL) \
		--build-arg KOPANO_ZPUSH_REPOSITORY_URL=$(KOPANO_ZPUSH_REPOSITORY_URL) \
		--build-arg RELEASE_KEY_DOWNLOAD=$(RELEASE_KEY_DOWNLOAD) \
		--build-arg DOWNLOAD_COMMUNITY_PACKAGES=$(DOWNLOAD_COMMUNITY_PACKAGES) \
		--build-arg ADDITIONAL_KOPANO_PACKAGES=$(ADDITIONAL_KOPANO_PACKAGES) \
		--build-arg ADDITIONAL_KOPANO_WEBAPP_PLUGINS=$(ADDITIONAL_KOPANO_WEBAPP_PLUGINS) \
		--cache-from $(docker_repo)/kopano_$(component):builder \
		-t $(docker_repo)/kopano_$(component) $(component)/

.PHONY: build-simple
build-simple: component ?= ssl
build-simple: ## Helper target to build a simplified image (no Kopano repo integration).
	docker build \
		--build-arg VCS_REF=$(vcf_ref) \
		--build-arg docker_repo=$(docker_repo) \
		-t $(docker_repo)/kopano_$(component) $(component)/

.PHONY: build-builder
build-builder: component ?= kdav
build-builder: ## Helper target for images with a build stage.
ifdef TRAVIS
	@echo "fetching previous build to warm up build cache (only on travis)"
	docker pull  $(docker_repo)/kopano_$(component):builder || true
endif
	docker build --target builder \
		--build-arg VCS_REF=$(vcf_ref) \
		--build-arg docker_repo=${docker_repo} \
		--build-arg KOPANO_CORE_VERSION=${core_download_version} \
		--build-arg KOPANO_$(COMPONENT)_VERSION=${$(component)_download_version} \
		--build-arg KOPANO_CORE_REPOSITORY_URL=$(KOPANO_CORE_REPOSITORY_URL) \
		--build-arg KOPANO_MEET_REPOSITORY_URL=$(KOPANO_MEET_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_REPOSITORY_URL=$(KOPANO_WEBAPP_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_FILES_REPOSITORY_URL=$(KOPANO_WEBAPP_FILES_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_MDM_REPOSITORY_URL=$(KOPANO_WEBAPP_MDM_REPOSITORY_URL) \
		--build-arg KOPANO_WEBAPP_SMIME_REPOSITORY_URL=$(KOPANO_WEBAPP_SMIME_REPOSITORY_URL) \
		--build-arg KOPANO_ZPUSH_REPOSITORY_URL=$(KOPANO_ZPUSH_REPOSITORY_URL) \
		--build-arg RELEASE_KEY_DOWNLOAD=$(RELEASE_KEY_DOWNLOAD) \
		--build-arg DOWNLOAD_COMMUNITY_PACKAGES=$(DOWNLOAD_COMMUNITY_PACKAGES) \
		--build-arg ADDITIONAL_KOPANO_PACKAGES="$(ADDITIONAL_KOPANO_PACKAGES)" \
		--build-arg ADDITIONAL_KOPANO_WEBAPP_PLUGINS="$(ADDITIONAL_KOPANO_WEBAPP_PLUGINS)" \
		--cache-from $(docker_repo)/kopano_$(component):builder \
		-t $(docker_repo)/kopano_$(component):builder $(component)/
		@echo $(docker_repo)/kopano_$(component):builder >> $(TAG_FILE)

build-base: ## Build new base image.
	docker pull debian:stretch
	component=base make build

build-core:
	component=core make build

build-konnect:
	component=konnect make build-simple

build-kwmserver:
	component=kwmserver make build-simple

build-ldap:
	component=ldap make build-simple

build-ldap-demo:
	component=ldap_demo make build-simple

build-meet:
	component=meet make build

build-php:
	component=php make build

build-playground:
	component=playground make build-builder
	component=playground make build-simple

build-python:
	component=python make build

build-kdav:
	docker pull composer:1.8
	component=kdav make build-builder
	component=kdav make build

build-scheduler:
	docker pull docker:18.09
	component=scheduler make build-simple

build-ssl:
	docker pull alpine:3.9
	component=ssl make build-simple

build-utils:
	component=utils make build

build-web:
	component=web make build-simple

build-webapp:
	component=webapp make build

build-webapp-demo: ## Replaces the actual kopano_webapp container with one that has login hints for demo.kopano.com.
	docker build \
		-f webapp/Dockerfile.demo \
		-t $(docker_repo)/kopano_webapp webapp/

build-zpush:
	component=zpush make build

tag-all: build-all ## Helper target to create tags for all images.
	make $(shell grep -o ^tag-.*: Makefile | grep -Ev 'tag-all|tag-container' | uniq | sed s/://g | xargs)

tag-container: component ?= base
tag-container: ## Helper target to tag a given image. Defaults to the base image.
	# TODO how to tag additional releases. e.g. also tag 8.7.80.1035 as 8.7.80?
	@echo 'create tag $($(component)_version)'
	docker tag $(docker_repo)/kopano_$(component) $(docker_repo)/kopano_$(component):${$(component)_version}
	@echo $(docker_repo)/kopano_$(component):${$(component)_version} >> $(TAG_FILE)
	@echo 'create tag latest'
	docker tag $(docker_repo)/kopano_$(component) $(docker_repo)/kopano_$(component):latest
	git commit -m 'ci: committing changes for $(component)' -- $(component) || true
	git tag $(component)/${$(component)_version} || true

tag-base:
	$(eval base_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_base))
	component=base make tag-container

tag-core:
	$(eval core_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_core | cut -d+ -f1))
	component=core make tag-container

tag-konnect:
	$(eval konnect_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_konnect))
	component=konnect make tag-container

tag-kwmserver:
	$(eval kwmserver_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_kwmserver))
	component=kwmserver make tag-container

tag-ldap:
	$(eval ldap_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_ldap))
	component=ldap make tag-container
	$(eval ldap_demo_version := $(ldap_version))
	component=ldap_demo make tag-container

tag-meet:
	$(eval meet_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_meet | cut -d+ -f1))
	component=meet make tag-container

tag-php:
	$(eval php_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_php | cut -d- -f1))
	component=php make tag-container

tag-python:
	$(eval python_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_python | cut -d- -f1))
	component=python make tag-container

tag-scheduler:
	$(eval scheduler_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_scheduler))
	component=scheduler make tag-container

tag-ssl:
	$(eval ssl_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_ssl))
	component=ssl make tag-container

tag-utils:
	$(eval utils_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_utils | cut -d- -f1))
	component=utils make tag-container

tag-web:
	$(eval web_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_web))
	component=web make tag-container

tag-webapp:
	$(eval webapp_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_webapp | cut -d+ -f1))
	component=webapp make tag-container

tag-zpush:
	$(eval zpush_version := \
	$(shell docker inspect --format '{{ index .Config.Labels "org.label-schema.version"}}' $(docker_repo)/kopano_zpush | cut -d+ -f1))
	component=zpush make tag-container

# Docker publish
repo-login: ## Login at hub.docker.com
	@echo $(docker_pwd) | docker login -u $(docker_login) --password-stdin

.PHONY: publish
publish: repo-login
	make $(shell grep -o ^publish-.*: Makefile | grep -Ev 'publish-container' | uniq | sed s/://g | xargs)

publish-container: component ?= base
publish-container: ## Helper target to push a given image to a registry. Defaults to the base image.
	@echo 'publish latest to $(docker_repo)/kopano_$(component)'
	docker push $(docker_repo)/kopano_$(component):${$(component)_version}
	docker push $(docker_repo)/kopano_$(component):latest
ifdef DOCKERREADME
	.travis/docker-hub-helper.sh $(component)
endif

publish-base: tag-base
	component=base make publish-container

publish-core: tag-core
	component=core make publish-container

publish-konnect: tag-konnect
	component=konnect make publish-container

publish-kwmserver: tag-kwmserver
	component=kwmserver make publish-container

publish-ldap: tag-ldap
	component=ldap make publish-container

publish-ldap-demo: tag-ldap
	component=ldap_demo make publish-container

publish-meet: tag-meet
	component=meet make publish-container

publish-php: tag-php
	component=php make publish-container

publish-playground:
	docker push $(docker_repo)/kopano_playground:latest
	docker push $(docker_repo)/kopano_playground:builder

publish-python: tag-python
	component=python make publish-container

publish-kdav: #tag-kdav
	docker push $(docker_repo)/kopano_kdav:latest
	docker push $(docker_repo)/kopano_kdav:builder

publish-scheduler: tag-scheduler
	component=scheduler make publish-container

publish-ssl: tag-ssl
	component=ssl make publish-container

publish-utils: tag-utils
	component=utils make publish-container

publish-web: tag-web
	component=web make publish-container

publish-webapp: tag-webapp
	component=webapp make publish-container

publish-zpush: tag-zpush
	component=zpush make publish-container

lint:
	git ls-files | xargs eclint check
	grep -rIl '^#![[:blank:]]*/bin/\(bash\|sh\|zsh\)' \
	--exclude-dir=.git --exclude=*.sw? \
	| xargs shellcheck -x
	git ls-files --exclude='*.yml' --ignored | xargs --max-lines=1 yamllint
	# List files which name starts with 'Dockerfile'
	# eg. Dockerfile, Dockerfile.build, etc.
	git ls-files --exclude='Dockerfile*' --ignored | xargs --max-lines=1 hadolint

.PHONY: clean
clean:
	docker-compose -f $(DOCKERCOMPOSE_FILE) down -v --remove-orphans || true

.PHONY: test
test: ## Build and start new containers for testing (also deletes existing data volumes).
	docker-compose -f $(DOCKERCOMPOSE_FILE) down -v --remove-orphans || true
	make build-all
	docker-compose -f $(DOCKERCOMPOSE_FILE) build
	docker-compose -f $(DOCKERCOMPOSE_FILE) up -d
	docker-compose -f $(DOCKERCOMPOSE_FILE) ps

test-update-env: ## Recreate containers based on updated .env.
	docker-compose -f $(DOCKERCOMPOSE_FILE) up -d

.PHONY: test-ci
test-ci: test-startup

.PHONY: test-startup
test-startup: ## Test if all containers start up
	docker-compose -f $(DOCKERCOMPOSE_FILE) -f tests/test-container.yml build
	docker-compose -f $(DOCKERCOMPOSE_FILE) up -d
	docker-compose -f $(DOCKERCOMPOSE_FILE) ps
	docker-compose -f $(DOCKERCOMPOSE_FILE) -f tests/test-container.yml run test || \
		(docker-compose -f $(DOCKERCOMPOSE_FILE) -f tests/test-container.yml ps; \
		docker-compose -f $(DOCKERCOMPOSE_FILE) -f tests/test-container.yml stop; \
		docker rm kopano_test_run_1 2>/dev/null; \
		exit 1)
	docker-compose -f $(DOCKERCOMPOSE_FILE) -f tests/test-container.yml stop 2>/dev/null
	docker ps --filter name=kopano_test* -aq | xargs docker rm -f

# TODO this needs goss added to travis and dcgoss pulled from my own git repo
.PHONY: test-goss
test-goss: ## Test configuration of containers with goss
	GOSS_FILES_PATH=core/goss/server dcgoss run kopano_server
	GOSS_FILES_PATH=core/goss/dagent dcgoss run kopano_dagent
	GOSS_FILES_PATH=core/goss/gateway dcgoss run kopano_gateway
	GOSS_FILES_PATH=core/goss/ical dcgoss run kopano_ical
	GOSS_FILES_PATH=core/goss/grapi dcgoss run kopano_grapi
	GOSS_FILES_PATH=core/goss/kapi dcgoss run kopano_kapi
	GOSS_FILES_PATH=core/goss/montor dcgoss run kopano_monitor
	GOSS_FILES_PATH=core/goss/search dcgoss run kopano_search
	GOSS_FILES_PATH=core/goss/spooler dcgoss run kopano_spooler
	GOSS_FILES_PATH=webapp dcgoss run kopano_webapp

test-security: ## Scan containers with Trivy for known security risks (not part of CI workflow for now).
	cat $(TAG_FILE) | xargs -I % sh -c 'trivy --exit-code 0 --severity HIGH --quiet --auto-refresh %'
	cat $(TAG_FILE) | xargs -I % sh -c 'trivy --exit-code 1 --severity CRITICAL --quiet --auto-refresh %'
	rm $(TAG_FILE)

test-quick: ## Similar to test target, but does not delete existing data volumes and does not rebuild images.
	docker-compose -f $(DOCKERCOMPOSE_FILE) stop || true
	docker-compose -f $(DOCKERCOMPOSE_FILE) up -d
	docker-compose -f $(DOCKERCOMPOSE_FILE) ps

test-stop:
	docker-compose -f $(DOCKERCOMPOSE_FILE) stop || true
