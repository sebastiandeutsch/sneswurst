ASM = wla-65816
LINK = wlalink

sneswurst: sneswurst.o
		${LINK} -vr sneswurst.link sneswurst.smc
		open sneswurst.smc

sneswurst.o: sneswurst.asm header.inc InitSNES.asm LoadGraphics.asm
		${ASM} -vo sneswurst.asm
