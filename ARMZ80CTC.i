;@ ASM header for the Z80CTC emulator
;@

	ctcptr			.req r12

							;@ ARMZ80CTC.s
	.struct 0
	ctcCh0TConst:	.short 0
	ctcCh0TCount:	.short 0
	ctcCh0Reg:		.byte 0
	ctcCh0Vector:	.byte 0
	ctcCh0Trig:		.byte 0
	ctcCh0Active:	.byte 0

	ctcCh1TConst:	.short 0
	ctcCh1TCount:	.short 0
	ctcCh1Reg:		.byte 0
	ctcCh1Vector:	.byte 0
	ctcCh1Trig:		.byte 0
	ctcCh1Active:	.byte 0

	ctcCh2TConst:	.short 0
	ctcCh2TCount:	.short 0
	ctcCh2Reg:		.byte 0
	ctcCh2Vector:	.byte 0
	ctcCh2Trig:		.byte 0
	ctcCh2Active:	.byte 0

	ctcCh3TConst:	.short 0
	ctcCh3TCount:	.short 0
	ctcCh3Reg:		.byte 0
	ctcCh3Vector:	.byte 0
	ctcCh3Trig:		.byte 0
	ctcCh3Active:	.byte 0

	ctcTrig0FPtr:	.long 0
	ctcTrig1FPtr:	.long 0
	ctcTrig2FPtr:	.long 0
	ctcIrqFPtr:		.long 0

	ctcSize:

;@----------------------------------------------------------------------------

