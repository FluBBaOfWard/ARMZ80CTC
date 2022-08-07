;@
;@  ARMZ80CTC.s
;@  Z80CTC timer/irq chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2018-07-23.
;@  Copyright © 2018-2022 Fredrik Ahlström. All rights reserved.
;@
#ifdef __arm__
#include "ARMZ80CTC.i"

	.global Z80CTCReset
	.global Z80CTCUpdate
	.global Z80CTCRead
	.global Z80CTCWrite
	.global Z80CTCSetTrg0
	.global Z80CTCSetTrg1
	.global Z80CTCSetTrg2
	.global Z80CTCSetTrg3
	.global Z80CTCGetIrqVector
	.global Z80CTCIrqAcknowledge

	.syntax unified

	.section .text
	.align 2
	.arm

;@----------------------------------------------------------------------------
Z80CTCReset:				;@ ctcptr = r12 = pointer to struct
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,ctcptr
	mov r1,#ctcSize/4
	bl memclr_

	adr r0,dummyFunc
	str r0,[ctcptr,#ctcIrqFPtr]

	ldmfd sp!,{lr}
dummyFunc:
	bx lr

;@----------------------------------------------------------------------------
Z80CTCUpdate:				;@ r0 = cycles, ctcptr = r12 = pointer to struct
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r3-r6,lr}

	mov r6,ctcptr
	mov r5,#4
updLoop:
	ldmia r6,{r3-r4}
	tst r4,#0x40				;@ Timer / Counter?
	bleq updateChannel			;@ Timer mode.
	add r6,r6,#8
	subs r5,r5,#1
	bhi updLoop

	ldmfd sp!,{r0,r3-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
updateChannel:
;@----------------------------------------------------------------------------
	tst r4,#0x01000000			;@ Channel active?
	bxeq lr
	tst r4,#0x20				;@ Prescaler 16 or 256
	mov r1,r0,lsl#16
	moveq r1,r1,lsl#4
	adds r3,r3,r1
	bcc updateEnd
	sub r3,r3,r3,lsl#24
	orr r4,r4,#0x80000000		;@ Channel trigged
	stmia r6,{r3,r4}
	ands r0,r4,#0x80			;@ Set IRQ pin?
	ldrne r1,[ctcptr,#ctcIrqFPtr]
	bxne r1
	bx lr
updateEnd:
	stmia r6,{r3,r4}
	bx lr
;@----------------------------------------------------------------------------
Z80CTCRead:				;@ r1 = adress, ctcptr = r12 = pointer to struct
;@----------------------------------------------------------------------------
mov r11,r11
	and r1,r1,#0x03
	add r1,ctcptr,r1,lsl#3
	ldrb r0,[r1,#3]				;@ Get current count
	rsb r0,r0,#0
	and r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Z80CTCWrite:			;@ r0 = data, r1 = adress, ctcptr = r12 = pointer to struct
;@----------------------------------------------------------------------------
mov r11,r11
	and r1,r1,#0x03
	add r2,ctcptr,r1,lsl#3
	ldr r1,[r2,#ctcCh0Reg]		;@ Get old reg
	tst r1,#0x04				;@ Should we write time constant?
	bne Z80WriteTime
	tst r0,#0x01				;@ Control write?
	strbeq r0,[ctcptr,#ctcCh0Vector]	;@ Write vector reg
	bxeq lr

	tst r0,#0x02				;@ Reset?
	bicne r1,r1,#0x01000000
	strb r0,[r2,#ctcCh0Reg]		;@ Write control reg

	bx lr

;@----------------------------------------------------------------------------
Z80WriteTime:
;@----------------------------------------------------------------------------
	sub r0,r0,r0,lsl#24
	str r0,[r2,#ctcCh0TConst]
	bic r1,r1,#0x04				;@ Clear time constant bit
	tst r1,#0x08				;@ Should we start timer immediately?
	orreq r1,r1,#0x01000000
	str r1,[r2,#ctcCh0Reg]		;@ Write back reg
	bx lr
;@----------------------------------------------------------------------------
Z80CTCSetTrg0:
;@----------------------------------------------------------------------------
	mov r2,ctcptr
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg1:
;@----------------------------------------------------------------------------
	add r2,ctcptr,#8
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg2:
;@----------------------------------------------------------------------------
	add r2,ctcptr,#16
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg3:
;@----------------------------------------------------------------------------
	add r2,ctcptr,#24
z80Trig:
	stmfd sp!,{r3-r4,lr}
	ldmia r2,{r3-r4}
	cmp r0,#0
	movne r0,#1
	ldrb r1,[r2,#ctcCh0Trig]
	eors r1,r1,r0
	tstne r4,#0x40			;@ Counter?
	beq z80TrigEnd
	strb r0,[r2,#ctcCh0Trig]
	adds r3,r3,#0x01000000
	bcc z80TrigEnd
	subcs r3,r3,r3,lsl#24
	orrcs r4,r4,#0x80000000	;@ Channel trigged?
	ands r0,r4,#0x80		;@ Set IRQ pin?
	ldrne r1,[ctcptr,#ctcIrqFPtr]
	blxne r1

z80TrigEnd:
	stmia r2,{r3-r4}
	ldmfd sp!,{r3-r4,lr}
	bx lr

;@----------------------------------------------------------------------------
Z80CTCGetIrqVector:
;@----------------------------------------------------------------------------
	ldrb r0,[ctcptr,#ctcCh0Vector]
	and r0,r0,#0xF8

	ldr r1,[ctcptr,#ctcCh0Reg]
	tst r1,#0x80000000			;@ Channel trigged?
	bxne lr

	ldr r1,[ctcptr,#ctcCh1Reg]
	tst r1,#0x80000000			;@ Channel trigged?
	orrne r0,r0,#0x02
	bxne lr

	ldr r1,[ctcptr,#ctcCh2Reg]
	tst r1,#0x80000000			;@ Channel trigged?
	orrne r0,r0,#0x04
	bxne lr

	ldr r1,[ctcptr,#ctcCh3Reg]
	tst r1,#0x80000000			;@ Channel trigged?
	orrne r0,r0,#0x06

	bx lr
;@----------------------------------------------------------------------------
Z80CTCIrqAcknowledge:
;@----------------------------------------------------------------------------
	ldr r1,[ctcptr,#ctcIrqFPtr]
	mov r0,#0

	ldr r2,[ctcptr,#ctcCh0Reg]
	tst r2,#0x80000000			;@ Channel trigged?
	bic r2,r2,#0x80000000
	str r2,[ctcptr,#ctcCh0Reg]
	bxne r1

	ldr r2,[ctcptr,#ctcCh1Reg]
	tst r2,#0x80000000			;@ Channel trigged?
	bic r2,r2,#0x80000000
	str r2,[ctcptr,#ctcCh1Reg]
	bxne r1

	ldr r2,[ctcptr,#ctcCh2Reg]
	tst r2,#0x80000000			;@ Channel trigged?
	bic r2,r2,#0x80000000
	str r2,[ctcptr,#ctcCh2Reg]
	bxne r1

	ldr r2,[ctcptr,#ctcCh3Reg]
	tst r2,#0x80000000			;@ Channel trigged?
	bic r2,r2,#0x80000000
	str r2,[ctcptr,#ctcCh3Reg]
	bxne r1

	bx lr

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
