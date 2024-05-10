//
//  ARMZ80CTC.h
//  Z80 CTC (Z8430) timer/irq chip emulator for arm32.
//
//  Created by Fredrik Ahlström on 2018-07-23.
//  Copyright © 2018-2024 Fredrik Ahlström. All rights reserved.
//

#ifndef Z80CTC_HEADER
#define Z80CTC_HEADER

typedef struct {
	u16 ch0TConst;
	u16 ch0TCount;
	u8 ch0Reg;
	u8 ch0Vector;
	u8 ch0Trig;
	u8 ch0Active;

	u16 ch1TConst;
	u16 ch1TCount;
	u8 ch1Reg;
	u8 ch1Vector;
	u8 ch1Trig;
	u8 ch1Active;

	u16 ch2TConst;
	u16 ch2TCount;
	u8 ch2Reg;
	u8 ch2Vector;
	u8 ch2Trig;
	u8 ch2Active;

	u16 ch3TConst;
	u16 ch3TCount;
	u8 ch3Reg;
	u8 ch3Vector;
	u8 ch3Trig;
	u8 ch3Active;

	void (*trig0FPtr)(bool);
	void (*trig1FPtr)(bool);
	void (*trig2FPtr)(bool);
	void (*irqFPtr)(bool);
} Z80CTC;

void Z80CTCReset(Z80CTC *chip);
void Z80CTCUpdate(int cycles, Z80CTC *chip);
char Z80CTCRead(Z80CTC *chip, u8 adress);
void Z80CTCWrite(u8 value, u8 adress, Z80CTC *chip);
void Z80CTCSetTrg0(bool value, Z80CTC *chip);
void Z80CTCSetTrg1(bool value, Z80CTC *chip);
void Z80CTCSetTrg2(bool value, Z80CTC *chip);
void Z80CTCSetTrg3(bool value, Z80CTC *chip);
char Z80CTCGetIrqVector(Z80CTC *chip);
char Z80CTCIrqAcknowledge(Z80CTC *chip);

#endif
