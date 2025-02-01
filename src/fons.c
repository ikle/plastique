/*
 * Source Stream
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <stdlib.h>

#include "fons.h"

int fons_init (struct fons *o, const char *path)
{
	o->input = NULL;

	if (!fons_push (o, path))
		return 0;

	blob_init (&o->line);
	return 1;
}

void fons_fini (struct fons *o)
{
	blob_fini (&o->line);

	while (o->input != NULL)
		fons_pop (o);
}

struct blob *fons_read (struct fons *o)
{
	struct fons_input *in;
	struct blob *line = &o->line;
	ssize_t n;

	while ((in = o->input) != NULL) {
		if ((n = getline (&line->data, &line->size, in->file)) != -1) {
			line->count = n;
			return line;
		}

		if (!feof (in->file))
			return NULL;  /* report error */

		fons_pop (o);
	}

	errno = 0;
	return NULL;  /* report EOF */
}

int fons_push (struct fons *o, const char *path)
{
	struct fons_input *in;

	if ((in = malloc (sizeof (*in))) == NULL)
		return 0;

	if ((in->file = fopen (path, "rb")) == NULL)
		goto no_open;

	in->next = o->input;
	o->input = in;
	return 1;
no_open:
	free (in);
	return 0;
}

void fons_pop (struct fons *o)
{
	struct fons_input *in = o->input;

	if (in != NULL) {
		o->input = in->next;
		fclose (in->file);
		free (in);
	}
}
