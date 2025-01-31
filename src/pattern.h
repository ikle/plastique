/*
 * Pattern Pair
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PATTERN_H
#define PATTERN_H  1

#include <stddef.h>

struct pattern {
	size_t len;
	char *name, *value;
};

int  pattern_init (struct pattern *o, const char *name, const char *value);
void pattern_fini (struct pattern *o);

#endif  /* PATTERN_H */
