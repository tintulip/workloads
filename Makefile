.ONESHELL:
.SHELL := /usr/bin/bash
.PHONY: plan apply prep
TF_DIR="./environments/$(ENV)"

set-env:
	@if [ -z $(ENV) ]; then \
		echo "ENV has not been set"; \
		ERROR=1; \
	 fi; \
	if [ -z $(AWS_REGION) ]; then \
		echo "AWS_REGION has not been set"; \
		ERROR=1; \
	fi; \
	if [ -z $(AWS_PROFILE) ]; then \
		echo "AWS_PROFILE has not been set"; \
		ERROR=1; \
	fi; \
	if [ ! -z $${ERROR} ] && [ $${ERROR} -eq 1 ]; then \
		echo "Example usage: \`AWS_PROFILE=<profile name> AWS_REGION=<region> ENV=<env name> make plan\`"; \
		exit 1; \
	fi;

prep: set-env
	@terraform -chdir=$(TF_DIR) init

plan: prep
	@terraform -chdir=$(TF_DIR) plan

apply: prep
	@terraform -chdir=$(TF_DIR) apply