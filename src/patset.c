/*
 * Pattern Set
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "patset.h"

void patset_init (struct patset *o)
{
	o->count  = 0;
	o->size   = 0;
	o->set    = NULL;
	o->sorted = 0;
}

void patset_fini (struct patset *o)
{
	size_t i;

	for (i = 0; i < o->count; ++i)
		pattern_fini (o->set + i);

	free (o->set);
}

static int pat_cmp (const void *a, const void *b)
{
	const struct pattern *l = a, *r = b;

	return strcmp (l->name, r->name);
}

void patset_sort (struct patset *o)
{
	if (o->sorted)
		return;

	qsort (o->set, o->count, sizeof (o->set[0]), pat_cmp);
	o->sorted = 1;
}

static int key_cmp (const void *key, const void *b)
{
	const struct pattern *p = b;

	return strcmp (key, p->name);
}

struct pattern *patset_find (struct patset *o, const char *name)
{
	patset_sort (o);

	return bsearch (name, o->set, o->count, sizeof (o->set[0]), key_cmp);
}

static int patset_resize (struct patset *o)
{
	struct pattern *p;
	const size_t next = o->size + 4;
	const size_t have = o->size * sizeof (p[0]);
	const size_t need = next    * sizeof (p[0]);

	if (need < have) {	/* size overflow */
		errno = ENOMEM;
		return 0;
	}

	if ((p = realloc (o->set, need)) == NULL)
		return 0;

	o->set  = p;
	o->size = next;
	return 1;
}

int patset_add (struct patset *o, const char *name, const char *value)
{
	if (o->count >= o->size && !patset_resize (o))
		return 0;

	if (!pattern_init (o->set + o->count, name, value))
		return 0;

	++o->count;
	o->sorted = 0;
	return 1;
}

int patset_del (struct patset *o, const char *name)
{
	struct pattern *p;

	if ((p = patset_find (o, name)) == NULL)
		return 0;

	pattern_fini (p);
	--o->count;

	memmove (p, p + 1, ((o->set + o->count) - (p + 1)) * sizeof (p[0]));
	return 1;
}
