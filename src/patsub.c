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

#include "patset.h"

struct patsub {
	struct patset *P;	/* pattern set				*/

	size_t N, space;	/* source string length and space	*/
	const char **SA;	/* sorted array of non-empty suffixes	*/
	const struct pattern **M; /* pattern marks for source positions	*/
};

void patsub_init (struct patsub *o, struct patset *P)
{
	o->P      = P;
	o->N      = 0;
	o->space  = 0;
	o->SA     = NULL;
	o->M      = NULL;
}

void patsub_fini (struct patsub *o)
{
	free (o->M);
	free (o->SA);
}

/*
 * 3. Mark string positions with matched patterns
 */

static int patsub_resize (struct patsub *o)
{
	const char **SA;
	const struct pattern **M;  /* W: sizeof M[0] == sizeof SA[0] */

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
	const struct pattern *P = o->P->set + p;

	return strncmp (P->name, o->SA[s], P->len);
}

static size_t find_any_pair (const struct patsub *o, size_t p, size_t s)
{
	/* to do: binary search */

	for (; p < o->P->count; ++p)
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

	if (o->N > o->space && !patsub_resize (o))
		return 0;

	for (i = 0; i < o->N; ++i) {
		o->SA[i] = S + i;		/* init suffixes	*/
		o->M[i]  = NULL;		/* init marks		*/
	}

	patset_sort (o->P);
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

		while ((p + 1) < o->P->count && cmp (o, p + 1, s) == 0)  ++p;

		o->M[o->SA[s] - S] = o->P->set + p;  /* mark pos. with a match */
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
