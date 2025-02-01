/*
 * CUPL Preprocessor
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <ctype.h>
#include <stdlib.h>
#include <strings.h>

#include "cupl-fons.h"

int cupl_fons_init (struct cupl_fons *o, const char *path)
{
	if (!fons_init (&o->in, path))
		return 0;

	patset_init (&o->vars);
	blob_init (&o->line);
	o->error = NULL;
	return 1;
}

void cupl_fons_fini (struct cupl_fons *o)
{
	blob_fini (&o->line);
	patset_fini (&o->vars);
	fons_fini (&o->in);
}

static int match_keyword (const struct blob *o, size_t i, const char *name)
{
	return strncasecmp (o->data + i, name, o->count - i) == 0;
}

static int isword (int a)
{
	return a == '_' || isalnum (a);
}

#define DEFINE_SKIP(type)						\
static size_t skip_##type (const struct blob *o, size_t i)		\
{									\
	const char *s = o->data;					\
									\
	for (; i < o->count && is##type (s[i]); ++i) {}			\
									\
	return i;							\
}

DEFINE_SKIP (space)
DEFINE_SKIP (graph)
DEFINE_SKIP (word)

static int do_include (struct cupl_fons *o, struct blob *line, size_t s)
{
	char *p = line->data;
	const size_t ps = skip_space (line, s);		/* path start	*/
	const size_t pe = skip_graph (line, ps);
	const size_t e  = skip_space (line, pe);

	if (p[e] != '\0') {
		o->error = "Too many arguments for include directive";
		return 0;
	}

	p[pe] = '\0';

	return fons_push (&o->in, p + ps);
}

static int do_define (struct cupl_fons *o, struct blob *line, size_t s)
{
	char *p = line->data;
	const size_t ns = skip_space (line, s);
	const size_t ne = skip_word  (line, ns);	/* name start	*/
	const size_t vs = skip_space (line, ne);
	const size_t ve = skip_graph (line, vs);	/* value start	*/
	const size_t e  = skip_space (line, ve);

	if (ne == ns) {
		o->error = "The define directive requires an argument";
		return 0;
	}

	if (p[e] != '\0') {
		o->error = "Too many arguments for define directive";
		return 0;
	}

	p[ne] = '\0';
	p[ve] = '\0';

	return patset_add (&o->vars, p + ns, p + vs);
}

struct blob *cupl_fons_read (struct cupl_fons *o)
{
	struct blob *line;
	size_t s;
loop:
	if ((line = fons_read (&o->in)) == NULL)
		return NULL;

	s = skip_space (line, 0);

	if (match_keyword (line, s, "$include")) {
		if (!do_include (o, line, s + 8))
			return NULL;

		goto loop;
	}

	if (match_keyword (line, s, "$define")) {
		if (!do_define (o, line, s + 7))
			return NULL;

		goto loop;
	}

//		o->error = "Unknown preprocessor directive";
//		return NULL;

	if (!blob_write (&o->line, line->data, line->count))
		return NULL;

	return &o->line;
}
