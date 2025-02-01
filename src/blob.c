/*
 * Resizeable Block of Data
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "blob.h"

static int blob_resize (struct blob *o, size_t size)
{
	void *data;

	if ((data = realloc (o->data, size)) == NULL)
		return 0;

	o->size = size;
	o->data = data;
	return 1;
}

int blob_write (struct blob *o, const char *data, size_t count)
{
	const size_t next = o->count + count;

	if (next < o->count) {		/* size overflow */
		errno = ENOMEM;
		return 0;
	}

	if (next > o->size && !blob_resize (o, next))
		return 0;

	memcpy (o->data + o->count, data, count);
	o->count = next;
	return 1;
}
