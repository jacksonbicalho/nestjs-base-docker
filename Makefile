-include .env

all : setup
.PHONY : all

setup:
	@echo "Installing dependencies"
	docker-compose run --rm nest yarn --skip-integrity-check --network-concurrency 1
