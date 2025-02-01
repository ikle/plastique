/*
 * Source Stream
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef FONS_H
#define FONS_H  1

#include <errno.h>
#include <stdio.h>

#include "blob.h"

struct fons_input {
	struct fons_input *next;
	FILE *file;
};

struct fons {
	struct fons_input *input;
	struct blob line;
};

/*
 * fons_init initializes a source stream objects, opens the specified file,
 * and pushes it onto the top of the stream source stack (see fons_push).
 *
 * fons_fini closes all files on the source stack and finalizess the source
 * stream object.
 */
int  fons_init (struct fons *o, const char *path);
void fons_fini (struct fons *o);

/*
 * fons_read attempts to read a line from the file on the top of the stream
 * source stack. Returns NULL if there is an error reading from the file.
 * If the end of file is reached, then closes the file on the top of the
 * stack and removes it from the top of the stack (see fons_pop), then
 * tries to read the line again. If the stack is empty, sets errno to zero
 * and returns NULL.
 */
struct blob *fons_read (struct fons *o);

/*
 * fons_push opens the specified file and pushes it onto the top of the
 * stream source stack.
 *
 * fons_pop closes the file on the top of the stream source stack and
 * removes it from the stack.
 */
int  fons_push (struct fons *o, const char *path);
void fons_pop  (struct fons *o);

#endif  /* FONS_H */
