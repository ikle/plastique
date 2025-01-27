/*
 * Dakota JEDEC File Format Helpers
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef DAKOTA_JEDEC_H
#define DAKOTA_JEDEC_H  1

#include <stddef.h>

struct jedec *jedec_alloc (const char *device);
void jedec_free (struct jedec *o);

const char *jedec_get_device (struct jedec *o);

int    jedec_get_default (struct jedec *o);
size_t jedec_get_count   (struct jedec *o);
void  *jedec_get_fuses   (struct jedec *o);

int jedec_set_count   (struct jedec *o, size_t count);
int jedec_set_default (struct jedec *o, int def);
int jedec_set_device  (struct jedec *o, const char *device);

struct jedec *jedec_load (const char *path);
int jedec_save (struct jedec *o, const char *path);

#endif  /* DAKOTA_JEDEC_H */
