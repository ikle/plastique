/*
 * Dakota JEDEC File Format Helpers
 *
 * Copyright (c) 2022-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dakota/jedec.h>

struct jedec {
	char device[32];

	int def;
	size_t count;
	void *fuses;
};

struct jedec *jedec_alloc (const char *device)
{
	struct jedec *o;

	if ((o = malloc (sizeof (*o))) == NULL)
		return NULL;

	jedec_set_device (o, device);

	o->def   = 0;
	o->count = 0;
	o->fuses = NULL;

	return o;
}

void jedec_free (struct jedec *o)
{
	if (o == NULL)
		return;

	free (o->fuses);
	free (o);
}

const char *jedec_get_device (struct jedec *o)
{
	return o->device[0] == '\0' ? NULL : o->device;
}

int jedec_get_default (struct jedec *o)
{
	return o->def;
}

size_t jedec_get_count (struct jedec *o)
{
	return o->count;
}

void *jedec_get_fuses (struct jedec *o)
{
	return o->fuses;
}

static void jedec_fuses_init (struct jedec *o)
{
	unsigned char *fuses = o->fuses;
	const size_t   full = o->count / 8;
	const unsigned tail = o->count & 7;
	int mask = o->def ? 0xff: 0;

	memset (fuses, mask, full);

	if (tail != 0)
		fuses[full] = mask >> (8 - tail);
}

int jedec_set_count (struct jedec *o, size_t count)
{
	const size_t len = (count + 7) / 8;

	if (o->fuses != NULL) {
		errno = EINVAL;
		return 0;
	}

	if ((o->fuses = malloc (len)) == NULL)
		return 0;

	o->count = count;
	return 1;
}

int jedec_set_default (struct jedec *o, int def)
{
	if (o->fuses == NULL || def < 0 || def > 1) {
		errno = EINVAL;
		return 0;
	}

	o->def = def;
	jedec_fuses_init (o);
	return 1;
}

int jedec_set_device (struct jedec *o, const char *device)
{
	snprintf (o->device, sizeof (o->device), "%s", device);
	return 1;
}

static int jedec_set_bit (struct jedec *o, size_t addr, int on)
{
	unsigned char *fuses = o->fuses;
	const size_t i = addr / 8;
	const unsigned mask = 1u << (addr & 7);

	if (addr >= o->count) {
		errno = EFAULT;
		return 0;
	}

	if (on)
		fuses[i] |= mask;
	else
		fuses[i] &= ~mask;

	return 1;
}

static int jedec_read_bits (struct jedec *o, size_t addr, const char *s)
{
	int ok = 1;

	for (; *s != '\0'; ++s)
		switch (*s) {
		case '0':
			ok &= jedec_set_bit (o, addr++, 0);
			break;

		case '1':
			ok &= jedec_set_bit (o, addr++, 1);
			break;
		}

	return ok;
}

static struct jedec *jedec_read (FILE *in)
{
	char device[32];
	struct jedec *o;
	int c;
	char *line = NULL;
	size_t avail = 0, n;
	ssize_t len;

	if ((o = jedec_alloc ("")) == NULL)
		return NULL;

	while ((c = fgetc (in)) != 2)
		if (c == EOF)
			goto error;

	while ((c = fgetc (in)) != 3) {
		if (c == EOF)
			goto error;

		if (isspace (c))
			continue;

		if ((len = getdelim (&line, &avail, '*', in)) < 1)
			goto error;

		line[len - 1] = '\0';

		switch (c) {
		case 'J':  /* to do: run for first block only */
			if (sscanf (line, "EDEC file for: %31s", device) == 1)
				jedec_set_device (o, device);

			break;

		case 'N':
			if (sscanf (line, " DEVICE %31s", device) == 1)
				jedec_set_device (o, device);

			break;

		case 'Q':
			if (sscanf (line, "F%zu", &n) == 1 &&
			    !jedec_set_count (o, n))
				goto error;

			break;

		case 'F':
			if (sscanf (line, "%d", &c) != 1 ||
			    !jedec_set_default (o, c))
				goto error;

			break;

		case 'L':
			if (o->fuses == NULL ||
			    sscanf (line, "%zu %n", &n, &c) != 1 ||
			    !jedec_read_bits (o, n, line + c))
				goto error;

			break;
		}
	}

	free (line);
	return o;
error:
	free (line);
	jedec_free (o);
	errno = EILSEQ;
	return NULL;
}

static int jedec_write_bits (FILE *out, const unsigned char *data, size_t count)
{
	size_t i;
	int c, ok = 1;

	for (i = 0; i < count; ++i) {
		c = (data[i / 8] & 1u << (i & 7)) != 0 ? '1' : '0';
		ok &= fputc (c, out) != EOF;
	}

	return ok;
}

static int jedec_write (struct jedec *o, FILE *out)
{
	const unsigned char *fuses = o->fuses;
	size_t i, count;
	int ok;

	ok = fprintf (out, "\002" "QF%zu*\n" "F%u*\n", o->count, o->def) > 0;

	if (o->device[0] != '\0')
		ok &= fprintf (out, "N DEVICE %s*\n", o->device) > 0;

	for (i = 0, count = o->count; count >= 64; i += 8, count -= 64) {
		ok &= fprintf (out, "L%06zu ", i * 8) > 0;
		ok &= jedec_write_bits (out, fuses + i, 64);
		ok &= fprintf (out, "*\n") > 0;
	}

	if (count > 0) {
		ok &= fprintf (out, "L%06zu ", i * 8) > 0;
		ok &= jedec_write_bits (out, fuses + i, count);
		ok &= fprintf (out, "*\n") > 0;
	}

	ok &= fprintf (out, "C0000*\0030000\n");

	return ok;
}

struct jedec *jedec_load (const char *path)
{
	FILE *in;
	struct jedec *o;

	if ((in = fopen (path, "rb")) == NULL)
		return 0;

	o = jedec_read (in);

	fclose (in);
	return o;
}

int jedec_save (struct jedec *o, const char *path)
{
	FILE *out;

	if ((out = fopen (path, "wb")) == NULL)
		return 0;

	if (!jedec_write (o, out))
		goto no_write;

	return fclose (out) == 0;
no_write:
	fclose (out);
	return 0;
}
