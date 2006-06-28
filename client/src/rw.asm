*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* READING/WRITING
*
* Read or write from zero to 40 ($28) blocks - inside
* a 64k Apple ][ buffer
*
* Input:
*   Y: Count of blocks
*   PARMBUF+1: unit number
*   BLKLO: starting block (lo)
*   BLKHI: starting block (hi)
*---------------------------------------------------------
READING
	lda #PMSG07
	sta SR_WR_C
	lda #PD_READ
	sta RWDIR
	lda #CHR_R
	sta RWCHR
	lda #CHR_BLK
	sta RWCHROK
	jmp RW_COMN

WRITING
	lda #PMSG08
	sta SR_WR_C
	lda #PD_WRIT
	sta RWDIR
	lda #CHR_W
	sta RWCHR
	lda #CHR_SP
	sta RWCHROK

RW_COMN
	sty BCOUNT
	lda #H_BUF	Column - r/w/s/r
	sta <CH
	lda #V_MSG	Message row
	jsr TABV
	ldy SR_WR_C
	jsr SHOWMSG

	lda #$00	Reposition cursor to beginning of
	sta <CH		buffer row
	lda #V_BUF
	jsr TABV

	jsr RWBLOX

	rts

*------------------------------------
* RWBLOX
*
* Read or write from zero to 40 ($28) blocks
* starting from BIGBUF
*
* Input:
*   PARMBUF+1: unit number
*   BLKLO: starting block (lo)
*   BLKHI: starting block (hi)
*------------------------------------

RWBLOX
	lda #$03	Set up MLI call - 3 parameters
	sta PARMBUF

	lda #BIGBUF	Point to the start of the big buffer
	sta PARMBUF+2
	lda /BIGBUF
	sta PARMBUF+3

RWCALL
	lda $C000
	cmp #CHR_ESC	ESCAPE = ABORT

	beq RABORT
	lda RWCHR
	jsr CHROVER

	lda <CH
	sta <COL_SAV

	lda #V_MSG	start printing at first number spot
	jsr TABV
	lda #H_NUM1
	sta <CH

	lda BLKLO
	clc
	adc #$01
	tax
	stx PRTPTR
	lda BLKHI
	bcc RW.NEXT
	clc
	adc #$01
RW.NEXT
	sta PRTPTR+1
	jsr PRTNUM	Print block number in decimal

	lda <COL_SAV	Reposition cursor to previous
	sta <CH		buffer row
	lda #V_BUF
	jsr TABV

	jsr MLI		MLI call: READ/WRITE
RWDIR	.db PD_READ
	.da PARMBUF
	bne RWBAD
	lda RWCHROK
	jsr COUT1
	jmp RWOK
RWBAD	lda #CHR_X
	jsr COUT1
RWOK	inc PARMBUF+3	Advance buffer $100 bytes
	inc PARMBUF+3	Advance buffer another $100 bytes
	inc BLKLO	Advance block counter by one (word width)
	bne RWNOB
	inc BLKHI
RWNOB	dec BCOUNT
	bne RWCALL
	rts

RABORT	jmp BABORT

RWCHR	.db CHR_R	Character to notify what we're doing
RWCHROK	.db CHR_BLK	Character to write when things are OK
BCOUNT	.db $00