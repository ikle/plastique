/*
 * Pattern Set
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PATSET_H
#define PATSET_H  1

#include "pattern.h"

struct patset {
	size_t count, size;	/* active patterns and available space	*/
	struct pattern *set;	/* pattern array			*/
	int sorted;		/* is pattern array sorted flag		*/
};

void patset_init (struct patset *o);
void patset_fini (struct patset *o);

int  patset_add  (struct patset *o, const char *name, const char *value);
int  patset_del  (struct patset *o, const char *name);
void patset_sort (struct patset *o);

struct pattern *patset_find (struct patset *o, const char *name);

#endif  /* PATSET_H*/
