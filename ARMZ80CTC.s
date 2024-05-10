;@
;@  ARMZ80CTC.s
;@  Z80 CTC (Z8430) timer/irq chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2018-07-23.
;@  Copyright © 2018-2024 Fredrik Ahlström. All rights reserved.
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
Z80CTCReset:				;@ ctcptr = r0 = pointer to struct
	.type Z80CTCReset STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}

	mov r4,r0
	mov r1,#ctcSize/4
	bl memclr_

	adr r0,dummyFunc
	str r0,[r4,#ctcTrig0FPtr]
	str r0,[r4,#ctcTrig1FPtr]
	str r0,[r4,#ctcTrig2FPtr]
	str r0,[r4,#ctcIrqFPtr]

	ldmfd sp!,{r4,lr}
dummyFunc:
	bx lr

;@----------------------------------------------------------------------------
Z80CTCUpdate:				;@ r0 = cycles, r1 = ctcptr
	.type Z80CTCUpdate STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r3-r6,lr}
	mov r4,r0
	mov ctcptr,r1

	mov r6,ctcptr
	mov r5,#4
updLoop:
	ldmia r6,{r2,r3}
	tst r3,#0x40				;@ Timer / Counter?
	bleq updateChannel			;@ Timer mode.
	add r6,r6,#8
	subs r5,r5,#1
	bhi updLoop

	ldmfd sp!,{r0,r3-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
updateChannel:
;@----------------------------------------------------------------------------
	tst r3,#0x01000000			;@ Channel active?
	bxeq lr
	tst r3,#0x20				;@ Prescaler 16 or 256
	mov r1,r4,lsl#16
	moveq r1,r1,lsl#4
	adds r2,r2,r1
	bcc updateEnd
	sub r2,r2,r2,lsl#24
	orr r3,r3,#0x80000000		;@ Channel trigged
	stmia r6,{r2,r3}
	ands r0,r3,#0x80			;@ Set IRQ pin?
	ldrne r1,[ctcptr,#ctcIrqFPtr]
	bxne r1
	bx lr
updateEnd:
	stmia r6,{r2,r3}
	bx lr
;@----------------------------------------------------------------------------
Z80CTCRead:				;@ r0 = ctcptr, r1 = adress
	.type Z80CTCRead STT_FUNC
;@----------------------------------------------------------------------------
mov r11,r11
	and r1,r1,#0x03
	add r1,r0,r1,lsl#3
	ldrb r0,[r1,#3]				;@ Get current count
	rsb r0,r0,#0
	and r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Z80CTCWrite:			;@ r0 = data, r1 = adress, ctcptr = r2
	.type Z80CTCWrite STT_FUNC
;@----------------------------------------------------------------------------
mov r11,r11
	and r1,r1,#0x03
	add r12,r2,r1,lsl#3
	ldr r1,[r12,#ctcCh0Reg]		;@ Get old reg
	tst r1,#0x04				;@ Should we write time constant?
	bne writeTime
	tst r0,#0x01				;@ Control write?
	strbeq r0,[r2,#ctcCh0Vector]	;@ Write vector reg
	bxeq lr

	tst r0,#0x02				;@ Reset?
	bicne r1,r1,#0x01000000
	strb r0,[r12,#ctcCh0Reg]		;@ Write control reg

	bx lr

;@----------------------------------------------------------------------------
writeTime:
;@----------------------------------------------------------------------------
	sub r0,r0,r0,lsl#24
	str r0,[r12,#ctcCh0TConst]
	bic r1,r1,#0x04				;@ Clear time constant bit
	tst r1,#0x08				;@ Should we start timer immediately?
	orreq r1,r1,#0x01000000
	str r1,[r12,#ctcCh0Reg]		;@ Write back reg
	bx lr
;@----------------------------------------------------------------------------
Z80CTCSetTrg0:			;@ r0 = val, r1=ctcptr
	.type Z80CTCSetTrg0 STT_FUNC
;@----------------------------------------------------------------------------
	mov r2,r1
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg1:			;@ r0 = val, r1=ctcptr
	.type Z80CTCSetTrg1 STT_FUNC
;@----------------------------------------------------------------------------
	add r2,r1,#8
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg2:			;@ r0 = val, r1=ctcptr
	.type Z80CTCSetTrg2 STT_FUNC
;@----------------------------------------------------------------------------
	add r2,r1,#16
	b z80Trig
;@----------------------------------------------------------------------------
Z80CTCSetTrg3:			;@ r0 = val, r1=ctcptr
	.type Z80CTCSetTrg3 STT_FUNC
;@----------------------------------------------------------------------------
	add r2,r1,#24
z80Trig:
	stmfd sp!,{r3-r4,lr}
	cmp r0,#0
	movne r0,#1
	ldrb r3,[r2,#ctcCh0Trig]
	teq r3,r0
	ldmia r2,{r3-r4}
	tstne r4,#0x40			;@ Counter?
	beq z80TrigEnd
	strb r0,[r2,#ctcCh0Trig]
	adds r3,r3,#0x01000000
	bcc z80TrigEnd
	subcs r3,r3,r3,lsl#24
	orrcs r4,r4,#0x80000000	;@ Channel trigged?
	ands r0,r4,#0x80		;@ Set IRQ pin?
	ldrne r1,[r1,#ctcIrqFPtr]
	blxne r1

z80TrigEnd:
	stmia r2,{r3-r4}
	ldmfd sp!,{r3-r4,lr}
	bx lr

;@----------------------------------------------------------------------------
Z80CTCGetIrqVector:			;@ r0=ctcptr
	.type Z80CTCGetIrqVector STT_FUNC
;@----------------------------------------------------------------------------
	mov ctcptr,r0
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
Z80CTCIrqAcknowledge:			;@ r0=ctcptr
	.type Z80CTCIrqAcknowledge STT_FUNC
;@----------------------------------------------------------------------------
	mov ctcptr,r0
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
