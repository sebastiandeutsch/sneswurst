ASM = wla-65816
LINK = wlalink

sneswurst: sneswurst.o
		${LINK} -vr sneswurst.link sneswurst.smc
		open sneswurst.smc

sneswurst.o: sneswurst.asm header.inc InitSNES.asm LoadGraphics.asm tiles.inc
		${ASM} -vo sneswurst.asm

gfx:
		@snesimg -f assets/graphics/sneswurst.psd -pf assets/graphics/palette.h -c asm -w 16 -h 16

clean:
	rm *.o
