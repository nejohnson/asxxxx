/* pdk.h */

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
 *
 *   This Assember Ported by
 *      John L. Hartman (JLH)
 *      jhartman at compuserve dot com
 *      noice at noicedebugger dot com
 *
 *   Padauk assemblers, from SDCC's SDAS (sdaspdk13/14/15), moved to
 *   this assembler's relocation:  code is word addressed and data is
 *   byte addressed, so a label has the address the instruction wants
 *   and the linker inserts it into the opcode with a bit mode.
 */

/*
 * Common to the Padauk 13, 14 and 15 bit cores, which share their
 * instruction set and differ in encodings and widths.  Each core is
 * its own assembler - aspdk13, aspdk14, aspdk15 - with its own
 * mnemonic table and machine(); the operand parsing, the emitters
 * and the relocation modes are here and in pdkadr.c, pdkmch.c and
 * pdkcom.c.
 */

/*
 * Instructions.
 */
#define S_MOV     50
#define S_LDT16   51
#define S_STT16   52
#define S_IDXM    53
#define S_XCH     54
#define S_PUSHAF  55
#define S_POPAF   56
#define S_ADD     57
#define S_ADDC    58
#define S_SUB     59
#define S_SUBC    60
#define S_INC     61
#define S_DEC     62
#define S_CLEAR   63
#define S_SR      64
#define S_SRC     65
#define S_SL      66
#define S_SLC     67
#define S_SWAP    68
#define S_AND     69
#define S_OR      70
#define S_XOR     71
#define S_NOT     72
#define S_NEG     73
#define S_SET0    74
#define S_SET1    75
#define S_CEQSN   76
#define S_T0SN    77
#define S_T1SN    78
#define S_IZSN    79
#define S_DZSN    80
#define S_CALL    81
#define S_GOTO    82
#define S_RET     83
#define S_RETI    84
#define S_NOP     85
#define S_PCADD   86
#define S_ENGINT  87
#define S_DISGINT 88
#define S_STOPSYS 89
#define S_STOPEXE 90
#define S_RESET   91
#define S_WDRESET 92
#define S_SWAPC   93  /* not on pdk13 */
#define S_CNEQSN  94
#define S_LDSPTL  95
#define S_LDSPTH  96
#define S_NADD    97  /* not on pdk13 */
#define S_COMP    98  /* not on pdk13 */
#define S_MUL     99
#define S_LDTABL  108 /* pdk15 only */
#define S_LDTABH  109 /* pdk15 only */

/*
 * Addressing modes.
 */
#define S_K    31	/* #k, an immediate */
#define S_A    32	/* a, the accumulator */
#define S_M    33	/* m, data memory */
#define S_IO   34	/* io, an I/O register */

/*
 * The .io mnemonics (mov.io, set0.io, ...) carry this flag, which
 * makes a bare operand an I/O register rather than data memory.
 */
#define PDK_OPCODE_ADR_IO 0x80000000
#define PDK_OPCODE_MASK     0xFFFFFF

/*
 * Relocation modes:  one for each operand field the cores use.  An
 * operand occupies the low bits of the 16-bit instruction word, so
 * every mode keeps its bits where they are; the mode gives the field
 * its width, and the width is the range check - the assembler checks
 * an absolute operand against it, the linker a relocatable one.
 *
 * The _E modes are for an operand that must be even (ldt16, stt16,
 * idxm, ldtabl, ldtabh):  bit 0 of the field belongs to the opcode,
 * the address goes in as it is, and an odd one is out of range.
 */
#define R_4BIT	0x0100		/* 0x000F */
#define R_5BIT	0x0200		/* 0x001F */
#define R_6BIT	0x0300		/* 0x003F */
#define R_7BIT	0x0400		/* 0x007F */
#define R_8BIT	0x0500		/* 0x00FF */
#define R_10BIT	0x0600		/* 0x03FF */
#define R_11BIT	0x0700		/* 0x07FF */
#define R_12BIT	0x0800		/* 0x0FFF */
#define R_5BITE	0x0900		/* 0x001E */
#define R_6BITE	0x0A00		/* 0x003E */
#define R_7BITE	0x0B00		/* 0x007E */
#define R_8BITE	0x0C00		/* 0x00FE */

/*
 * An instruction form:  the opcode, and the mask of its operand
 * field.  A mask of 0 means the form takes no operand.
 */
struct inst {
	a_uint op;
	a_uint mask;
};

	/* pdkadr.c */
extern	int		addr(struct expr *esp, int ioAdr);
extern	int		pdkbit(struct expr *esp);
extern	int		pdkreg(char *name);

	/* pdkmch.c */
extern	void		emov(a_uint op, struct inst def, struct inst ioa,
				struct inst aio, struct inst ma, struct inst am);
extern	void		eidxm(struct inst am, struct inst ma);
extern	void		earith(struct inst def, struct inst ma, struct inst am);
extern	void		earithc(struct inst ma, struct inst am, struct inst m,
				struct inst a);
extern	void		eshift(struct inst a, struct inst m);
extern	void		ebit(a_uint op, struct inst def, struct inst ma,
				struct inst am, struct inst *ioa);
extern	void		enot(struct inst def, struct inst m);
extern	void		ebitn(a_uint op, struct inst io, struct inst m,
				int offset);
extern	void		eskip(struct inst def, struct inst m);
extern	void		ezsn(struct inst def, struct inst m);
extern	void		eret(struct inst def, struct inst k);
extern	void		eone(struct inst m);
extern	void		exch(struct inst m);
extern	void		epupo(struct inst def);
extern	void		eopta(struct inst def);
extern	void		eswapc(a_uint op, struct inst iok, int offset);
extern	void		espec(struct inst am, struct inst ma);
extern	void		ejump(struct inst def);
extern	void		outpdkaw(struct inst inst, struct expr *esp);
extern	void		outpdkrm(struct inst inst, struct expr *esp);

	/* pdkxxmch.c */
extern	void		machine(struct mne *mp);
extern	void		minit(void);
