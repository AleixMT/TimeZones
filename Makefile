#-------------------------------------------------------------------------------
# Example Makefile to assembly, link and debug ARM source code (and C code)
# Author: Santiago Romaní, Pere Millán
# Date: February 2016, May 2017, March 2019, February/March 2020
# Licence: Public Domain
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# options for code generation
#-------------------------------------------------------------------------------
ASFLAGS	:= -march=armv5te -mlittle-endian -g
LDFLAGS := -z max-page-size=0x8000

ARCH	:=	-march=armv5te -mlittle-endian
CFLAGS	:=	-Wall -gdwarf-3 -O2 $(ARCH) -fomit-frame-pointer -ffast-math -c \
			-I./include 


#-------------------------------------------------------------------------------
# make commands
#-------------------------------------------------------------------------------

times.elf : build/times.o build/startup.o build/jocproves_t.o lib/test_utils.o
	arm-none-eabi-ld $(LDFLAGS) build/times.o build/startup.o build/jocproves_t.o lib/test_utils.o -o times.elf

build/times.o : source/FCtimes.s
	arm-none-eabi-as $(ASFLAGS) source/FCtimes.s -o build/times.o

build/startup.o : source/startup.s
	arm-none-eabi-as $(ASFLAGS) source/startup.s -o build/startup.o

build/jocproves_t.o: test/jocproves_t.c include/FCtimes.h include/test_utils.h
	arm-none-eabi-gcc $(CFLAGS) test/jocproves_t.c -o build/jocproves_t.o



lib/test_utils.o: lib/libsource/test_utils.c
	arm-none-eabi-gcc $(CFLAGS) lib/libsource/test_utils.c -o lib/test_utils.o


# Versió amb el codi de les rutines en C:
demoC: timesC.elf

timesC.elf : build/timesC.o build/startup.o build/jocproves_t.o lib/test_utils.o
	arm-none-eabi-ld $(LDFLAGS) build/timesC.o build/startup.o build/jocproves_t.o lib/test_utils.o -o timesC.elf

build/timesC.o : source/demoC/FCtimesC.c include/FCtimes.h
	arm-none-eabi-gcc $(CFLAGS) source/demoC/FCtimesC.c -o build/timesC.o




#-------------------------------------------------------------------------------
# clean commands
#-------------------------------------------------------------------------------
clean : 
	@rm -fv build/startup.o
	@rm -fv build/times.o
	@rm -fv build/jocproves_t.o
	@rm -fv times.elf
	@rm -fv build/timesC.o
	@rm -fv timesC.elf


#-------------------------------------------------------------------------------
# debug commands
#-------------------------------------------------------------------------------
debug : times.elf
	arm-eabi-insight times.elf &

debugC : timesC.elf
	arm-eabi-insight timesC.elf &

