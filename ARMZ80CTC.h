/*
*/

#ifndef Z80CTC_HEADER
#define Z80CTC_HEADER

typedef struct {
	u16 ctcCh0TConst;
	u16 ctcCh0TCount;
	u8 ctcCh0Reg;
	u8 ctcCh0Vector;
	u8 ctcCh0Trig;
	u8 ctcCh0Active;

	u16 ctcCh1TConst;
	u16 ctcCh1TCount;
	u8 ctcCh1Reg;
	u8 ctcCh1Vector;
	u8 ctcCh1Trig;
	u8 ctcCh1Active;

	u16 ctcCh2TConst;
	u16 ctcCh2TCount;
	u8 ctcCh2Reg;
	u8 ctcCh2Vector;
	u8 ctcCh2Trig;
	u8 ctcCh2Active;

	u16 ctcCh3TConst;
	u16 ctcCh3TCount;
	u8 ctcCh3Reg;
	u8 ctcCh3Vector;
	u8 ctcCh3Trig;
	u8 ctcCh3Active;

	u32 ctcTrig0FPtr;
	u32 ctcTrig1FPtr;
	u32 ctcTrig2FPtr;
	u32 ctcIrqFPtr;

} Z80CTC;


void Z80CTCReset(Z80CTC *chip);
void Z80CTCUpdate(Z80CTC *chip, int cycles);
char Z80CTCRead(Z80CTC *chip, null, u8 adress);
void Z80CTCWrite(Z80CTC *chip, u8 value, u8 adress);
void Z80CTCSetTrg0(Z80CTC *chip, bool value);
void Z80CTCSetTrg1(Z80CTC *chip, bool value);
void Z80CTCSetTrg2(Z80CTC *chip, bool value);
void Z80CTCSetTrg3(Z80CTC *chip, bool value);
char Z80CTCGetIrqVector(Z80CTC *chip);
char Z80CTCIrqAcknowledge(Z80CTC *chip);


#endif
