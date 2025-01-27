#
# Atmel Tools Helpers
#
# Copyright (c) 2025 Alexei A. Smekalkine <ikle@ikle.ru>
#
# SPDX-License-Identifier: BSD-2-Clause
#

ROOT ?= $(HOME)/cad

WRAPPERS = cupl fitter fit1500 fit1502 fit1504 fit1508

.PHONY: install

install: $(WRAPPERS)
	install -d $(ROOT)/bin
	install -t $(ROOT)/bin $^
