/*
 * CUPL Preprocessor
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef CUPL_FONS_H
#define CUPL_FONS_H  1

#include <stddef.h>

#include "blob.h"
#include "fons.h"
#include "patset.h"

struct cupl_fons {
	struct fons in;
	struct patset vars;
	struct blob line;

	const char *error;
};

int  cupl_fons_init (struct cupl_fons *o, const char *path);
void cupl_fons_fini (struct cupl_fons *o);

struct blob *cupl_fons_read (struct cupl_fons *o);

#endif  /* CUPL_FONS_H */
