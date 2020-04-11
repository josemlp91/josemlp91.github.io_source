.PHONY: help

.DEFAULT_GOAL := help

runner=$(shell whoami)
gitver=$(shell git log -1 --pretty=format:"%H")


help: ## This help.
	@echo
	@echo "\e[1;35m Port mapping used: $<\e[0m"
	@echo "\e[1;33m - Development server: localhost:4000 $<\e[0m"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo


build-dev: ## Build development docker images.
	@echo "Building development docker images"
	docker-compose build


build-pro: ## Build production docker images.
	@echo "Building production docker images"
	docker-compose -f docker-compose-prod.yml build


up: build-dev ## Run developer web server.
	docker-compose up

up-pro: build-pro ## Run production web server.
	docker-compose -f docker-compose-prod.yml up

publish:  ## Publish image in Docker Hub.
	docker login
	docker build -f Dockerfile.prod -t josemlp91/myblog:$(gitver) .
	docker push josemlp91/myblog
