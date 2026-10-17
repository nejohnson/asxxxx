/* pdkcom.c */

/*
 *  Copyright (C) 1998-2009  Alan R. Baldwin
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * Alan R. Baldwin
 * 721 Berkeley St.
 * Kent, Ohio  44240
 */

/*
 * The banks, areas and relocation modes the Padauk assemblers share.
 */

#include "asxxxx.h"
#include "pdk.h"

/*
 * Coding Banks
 *
 * Code and data are separate address spaces.  Neither bank has a
 * file suffix:  data memory holds nothing but .ds, so only code
 * reaches the output file.
 */
struct	bank	bank[2] = {
    {	NULL,		"_CSEG",	NULL,		0,	0,	0,	0,	0	},
    {	&bank[0],	"_DSEG",	NULL,		1,	0,	0,	0,	0	}
};

/*
 * Coding Areas
 *
 * Program memory is addressed in instruction words, data memory in
 * bytes.  An area takes _CODE's word length unless it says (DSEG).
 */
struct	area	area[2] = {
    {	NULL,		&bank[0],	"_CODE",	0,	0,	0,	A_2BYTE|A_BNK|A_CSEG	},
    {	&area[0],	&bank[1],	"_DATA",	1,	0,	0,	A_1BYTE|A_BNK|A_DSEG	}
};

/*
 * Basic Relocation Mode Definition
 *
 *	#define		R_NORM	0000		No Bit Positioning
 */
char	mode0[32] = {	/* R_NORM */
	'\200',	'\201',	'\202',	'\203',	'\204',	'\205',	'\206',	'\207',
	'\210',	'\211',	'\212',	'\213',	'\214',	'\215',	'\216',	'\217',
	'\220',	'\221',	'\222',	'\223',	'\224',	'\225',	'\226',	'\227',
	'\230',	'\231',	'\232',	'\233',	'\234',	'\235',	'\236',	'\237'
};

/*
 * Operand fields:  the low n bits of the instruction word, each bit
 * where it was.  '\2nn' is an active bit, going to bit nn.
 */
#define	ON(n)	((char) (0200 + (n)))
#define	OFF(n)	((char) (n))

#define	FIELD(n) {							\
	(n) > 0 ? ON(0) : OFF(0),	(n) > 1 ? ON(1) : OFF(1),	\
	(n) > 2 ? ON(2) : OFF(2),	(n) > 3 ? ON(3) : OFF(3),	\
	(n) > 4 ? ON(4) : OFF(4),	(n) > 5 ? ON(5) : OFF(5),	\
	(n) > 6 ? ON(6) : OFF(6),	(n) > 7 ? ON(7) : OFF(7),	\
	(n) > 8 ? ON(8) : OFF(8),	(n) > 9 ? ON(9) : OFF(9),	\
	(n) > 10 ? ON(10) : OFF(10),	(n) > 11 ? ON(11) : OFF(11),	\
	OFF(12), OFF(13), OFF(14), OFF(15),				\
	OFF(16), OFF(17), OFF(18), OFF(19), OFF(20), OFF(21), OFF(22),	\
	OFF(23), OFF(24), OFF(25), OFF(26), OFF(27), OFF(28), OFF(29),	\
	OFF(30), OFF(31)						\
}

/*
 * The even fields:  bit 0 is the opcode's, bits 1 to n-1 the
 * operand's.
 */
#define	EFIELD(n) {							\
	OFF(0),				(n) > 1 ? ON(1) : OFF(1),	\
	(n) > 2 ? ON(2) : OFF(2),	(n) > 3 ? ON(3) : OFF(3),	\
	(n) > 4 ? ON(4) : OFF(4),	(n) > 5 ? ON(5) : OFF(5),	\
	(n) > 6 ? ON(6) : OFF(6),	(n) > 7 ? ON(7) : OFF(7),	\
	OFF(8), OFF(9), OFF(10), OFF(11), OFF(12), OFF(13), OFF(14),	\
	OFF(15), OFF(16), OFF(17), OFF(18), OFF(19), OFF(20), OFF(21),	\
	OFF(22), OFF(23), OFF(24), OFF(25), OFF(26), OFF(27), OFF(28),	\
	OFF(29), OFF(30), OFF(31)					\
}

char	mode1[32]  = FIELD(4);		/* R_4BIT  */
char	mode2[32]  = FIELD(5);		/* R_5BIT  */
char	mode3[32]  = FIELD(6);		/* R_6BIT  */
char	mode4[32]  = FIELD(7);		/* R_7BIT  */
char	mode5[32]  = FIELD(8);		/* R_8BIT  */
char	mode6[32]  = FIELD(10);		/* R_10BIT */
char	mode7[32]  = FIELD(11);		/* R_11BIT */
char	mode8[32]  = FIELD(12);		/* R_12BIT */
char	mode9[32]  = EFIELD(5);		/* R_5BITE */
char	mode10[32] = EFIELD(6);		/* R_6BITE */
char	mode11[32] = EFIELD(7);		/* R_7BITE */
char	mode12[32] = EFIELD(8);		/* R_8BITE */

/*
 *	struct	mode
 *	{
 *		char *	m_def;		Bit Relocation Definition
 *		a_uint	m_flag;		Bit Swapping Flag
 *		a_uint	m_dbits;	Destination Bit Mask
 *		a_uint	m_sbits;	Source Bit Mask
 *	};
 *
 * No bit moves, so m_flag is 0 and both masks are the field.
 */
struct	mode	mode[13] = {
    {	&mode0[0],	0,	0x0000FFFF,	0x0000FFFF	},	/* R_NORM  */
    {	&mode1[0],	0,	0x0000000F,	0x0000000F	},	/* R_4BIT  */
    {	&mode2[0],	0,	0x0000001F,	0x0000001F	},	/* R_5BIT  */
    {	&mode3[0],	0,	0x0000003F,	0x0000003F	},	/* R_6BIT  */
    {	&mode4[0],	0,	0x0000007F,	0x0000007F	},	/* R_7BIT  */
    {	&mode5[0],	0,	0x000000FF,	0x000000FF	},	/* R_8BIT  */
    {	&mode6[0],	0,	0x000003FF,	0x000003FF	},	/* R_10BIT */
    {	&mode7[0],	0,	0x000007FF,	0x000007FF	},	/* R_11BIT */
    {	&mode8[0],	0,	0x00000FFF,	0x00000FFF	},	/* R_12BIT */
    {	&mode9[0],	0,	0x0000001E,	0x0000001E	},	/* R_5BITE */
    {	&mode10[0],	0,	0x0000003E,	0x0000003E	},	/* R_6BITE */
    {	&mode11[0],	0,	0x0000007E,	0x0000007E	},	/* R_7BITE */
    {	&mode12[0],	0,	0x000000FE,	0x000000FE	}	/* R_8BITE */
};

/*
 * Array of Pointers to mode Structures
 */
struct	mode	*modep[16] = {
	&mode[0],	&mode[1],	&mode[2],	&mode[3],
	&mode[4],	&mode[5],	&mode[6],	&mode[7],
	&mode[8],	&mode[9],	&mode[10],	&mode[11],
	&mode[12],	NULL,		NULL,		NULL
};
