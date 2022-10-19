# -*- mode:makefile; coding:utf-8 -*-
include common-dev-assets/plugin-assets/config.env
export

# explicitly tell Make these commands not associated with files
.PHONY: all dependency-install-darwin-linux dependency-pre-commit sem-release

#
# simply expanded variables
#

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
    detected_OS := Windows
else
    detected_OS := $(shell uname)  # same as "uname -s"
endif

.DEFAULT_GOAL = dependency-pre-commit
ifneq (,$(filter $(detected_OS), Darwin Linux))
	.DEFAULT_GOAL = all
endif

ifndef RUN
	RUN := ''
endif

#
# install dependencies
#

all: dependency-install-darwin-linux dependency-pre-commit

dependency-install-darwin-linux:
	./plugin-assets/install-deps.sh

dependency-pre-commit:
	pre-commit install
	pre-commit install --hook-type commit-msg

#
# release
#

sem-release:
	@mv -t /mnt /tmp/node_modules /tmp/package-lock.json && \
	npx semantic-release --no-ci
