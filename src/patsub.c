/*
 * Multiple Pattern Substitution
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>

/*
 * 1. Pattern with a string to replace with
 */

struct pat {
	size_t len;
	char *name, *value;
};

static int pat_init (struct pat *o, const char *name, const char *value)
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

static void pat_fini (struct pat *o)
{
	free (o->value);
	free (o->name);
}

/*
 * 2. Pattern substitution core
 */

struct patsub {
	size_t count, size;	/* active patterns and available space	*/
	struct pat *set;	/* sorted patterns			*/
	int sorted;		/* patterns sorted flag			*/

	size_t N, space;	/* source string length and space	*/
	const char **SA;	/* sorted array of non-empty suffixes	*/
	const struct pat **M;	/* pattern marks for source positions	*/
};

void patsub_init (struct patsub *o)
{
	o->count  = 0;
	o->size   = 0;
	o->set    = NULL;
	o->sorted = 0;

	o->N      = 0;
	o->space  = 0;
	o->SA     = NULL;
	o->M      = NULL;
}

void patsub_fini (struct patsub *o)
{
	size_t i;

	free (o->M);
	free (o->SA);

	for (i = 0; i < o->count; ++i)
		pat_fini (o->set + i);

	free (o->set);
}

static int pat_cmp (const void *a, const void *b)
{
	const struct pat *l = a, *r = b;

	return strcmp (l->name, r->name);
}

static void patsub_sort (struct patsub *o)
{
	if (o->sorted)
		return;

	qsort (o->set, o->count, sizeof (o->set[0]), pat_cmp);
	o->sorted = 1;
}

static int key_cmp (const void *key, const void *b)
{
	const struct pat *p = b;

	return strcmp (key, p->name);
}

static struct pat *patsub_find (struct patsub *o, const char *name)
{
	patsub_sort (o);

	return bsearch (name, o->set, o->count, sizeof (o->set[0]), key_cmp);
}

static int patsub_resize (struct patsub *o)
{
	struct pat *p;
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

int patsub_exists (struct patsub *o, const char *name)
{
	return patsub_find (o, name) != NULL;
}

int patsub_add (struct patsub *o, const char *name, const char *value)
{
	if (o->count >= o->size && !patsub_resize (o))
		return 0;

	if (!pat_init (o->set + o->count, name, value))
		return 0;

	++o->count;
	o->sorted = 0;
	return 1;
}

int patsub_del (struct patsub *o, const char *name)
{
	struct pat *p;

	if ((p = patsub_find (o, name)) == NULL)
		return 0;

	pat_fini (p);
	--o->count;

	memmove (p, p + 1, (o->set + o->count - (p + 1)) * sizeof (p[0]));
	return 1;
}

/*
 * 3. Mark string positions with matched patterns
 */

static int patsub_resize_marks (struct patsub *o)
{
	const char **SA;
	const struct pat **M;	/* W: sizeof M[0] == sizeof SA[0] */

	const size_t next = o->N;
	const size_t have = o->space * sizeof (SA[0]);
	const size_t need = next     * sizeof (SA[0]);

	if (need < have) {	/* size overflow */
		errno = ENOMEM;
		return 0;
	}

	if ((SA = realloc (o->SA, need)) == NULL)
		return 0;

	o->SA = SA;

	if ((M = realloc (o->M, need)) == NULL)
		return 0;

	o->M = M;
	o->space = next;
	return 1;
}

static int cmp (const struct patsub *o, size_t p, size_t s)
{
	const struct pat *P = o->set + p;

	return strncmp (P->name, o->SA[s], P->len);
}

static size_t find_any_pair (const struct patsub *o, size_t p, size_t s)
{
	/* to do: binary search */

	for (; p < o->count; ++p)
		if (cmp (o, p, s) == 0)
			return p;

	return -1;
}

static size_t find_first_suffix (const struct patsub *o, size_t p, size_t s)
{
	/* to do: binary search */

	for (; s < o->N; ++s)
		if (cmp (o, p, s) == 0)
			return s;

	return -1;
}

static int str_cmp (const void *L, const void *R)
{
	const char *const *pl = L;
	const char *const *pr = R;

	return strcmp (*pl, *pr);
}

static int patsub_mark (struct patsub *o, const char *S)
{
	size_t i, p = 0, s = 0;
	int a;

	o->N = strlen (S);			/* to do: resize SA & M	*/

	if (o->N > o->space && !patsub_resize_marks (o))
		return 0;

	for (i = 0; i < o->N; ++i) {
		o->SA[i] = S + i;		/* init suffixes	*/
		o->M[i]  = NULL;		/* init marks		*/
	}

	patsub_sort (o);
	qsort (o->SA, o->N, sizeof (o->SA[0]), str_cmp);

	for (; s < o->N; ++s) {
		if ((a = cmp (o, p, s)) < 0) {		/* find next p	*/
			if ((p = find_any_pair (o, p + 1, s)) == -1)
				return 1;
		}
		else if (a > 0) {			/* find next s	*/
			if ((s = find_first_suffix (o, p, s + 1)) == -1)
				return 1;
		}

		/* P[p] matches SA[s] now, find longest match */

		while ((p + 1) < o->count && cmp (o, p + 1, s) == 0)  ++p;

		o->M[o->SA[s] - S] = o->set + p;  /* mark pos. with a match */
	}

	return 1;
}

/*
 * 4. Apply patterns to source string
 */

static int emit_char (struct patsub *o, int a)
{
	return 0;  /* not implemented */
}

static int emit_string (struct patsub *o, const char *s)
{
	return 0;  /* not implemented */
}

int patsub_apply (struct patsub *o, const char *S)
{
	size_t i, n;

	if (!patsub_mark (o, S))
		return 0;

	for (i = 0; i < o->N; i += n)
		if (o->M[i] == NULL) {
			if (!emit_char (o, S[i]))
				return 0;

			n = 1;
		}
		else {
			if (!emit_string (o, o->M[i]->value))
				return 0;

			n = o->M[i]->len;
		}

	return 1;
}
