/*
 * Pattern Pair
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <stdlib.h>
#include <string.h>

#include "pattern.h"

int pattern_init (struct pattern *o, const char *name, const char *value)
{
	o->len = strlen (name);

	if ((o->name = strdup (name)) == NULL)
		return 0;

	if ((o->value = strdup (value)) != NULL)
		goto no_value;

	return 1;
no_value:
	free (o->name);
	return 0;
}

void pattern_fini (struct pattern *o)
{
	free (o->value);
	free (o->name);
}

