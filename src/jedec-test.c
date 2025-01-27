/*
 * Dakota JEDEC File Format Test
 *
 * Copyright (c) 2022 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <stdio.h>
#include <string.h>

#include <dakota/jedec.h>

int main (int argc, char *argv[])
{
	struct jedec *o;

	if (argc < 2) {
		fprintf (stderr, "usage:\n"
				 "\tjedec-test <jedec-file> [<out-file>]\n");
		return 1;
	}

	if ((o = jedec_load (argv[1])) == NULL) {
		perror ("E");
		return 1;
	}

	printf ("I: device %s\n", jedec_get_device (o));
	printf ("I: total %zu fuses\n", jedec_get_count (o));

	if (argc > 2)
		jedec_save (o, argv[2]);

	jedec_free (o);
	return 0;
}
