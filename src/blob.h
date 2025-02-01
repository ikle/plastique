/*
 * Resizeable Block of Data
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef BLOB_H
#define BLOB_H  1

#include <stddef.h>

struct blob {
	size_t count, size;	/* blob size and available space	*/
	void *data;		/* blob data				*/
};

static inline void blob_init (struct blob *o)
{
	o->count = 0;
	o->size  = 0;
	o->data  = NULL;
}

static inline void blob_fini (struct blob *o)
{
	free (o->data);
}

int blob_write (struct blob *o, const char *data, size_t count);

#endif  /* BLOB_H*/
