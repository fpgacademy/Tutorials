INSTALL := C:/altera_pro/26.1
MAIN	:= print.c
HDRS	:= address_map_niosv.h
SRCS	:= $(MAIN)

SHELL	:= cmd.exe

# The following variables are set based on the value of the INSTALL variable
COMPILER		:= $(INSTALL)/fpgacademy/AMP/cygwin64/home/compiler/bin
BASH			:= $(INSTALL)/fpgacademy/AMP/cygwin64/bin/bash --noprofile -norc -c 

# for Quartus programmer (three possible paths)
export PATH := $(INSTALL)/quartus/bin64/:$(PATH)
export PATH := $(INSTALL)/qprogrammer/quartus/bin64/:$(PATH)
export PATH := $(INSTALL)/qprogrammer/bin64/:$(PATH)
# for GDB server (two possible paths)
export PATH := $(INSTALL)/riscfree/debugger/gdbserver-riscv/:$(PATH)
export PATH := $(INSTALL)/fpgacademy/GDB/debugger/gdbserver-riscv/:$(PATH)
# for GDB client (two possible paths)
export PATH := $(INSTALL)/riscfree/toolchain/riscv32-unknown-elf/bin/:$(PATH)
export PATH := $(INSTALL)/fpgacademy/GDB/toolchain/riscv32-unknown-elf/bin/:$(PATH)
# for the nios2-terminal
export PATH := $(INSTALL)/fpgacademy/AMP/bin/:$(PATH)
# for checking JTAG chain
export PATH := $(INSTALL)/quartus/sopc_builder/bin/:$(PATH)

CYGWIN_INSTALL := $(shell $(BASH) 'export PATH=/usr/local/bin:/usr/bin; cygpath $(INSTALL)')
CYGWIN_PATH := export PATH=/usr/local/bin:/usr/bin:$(CYGWIN_INSTALL)/fpgacademy/AMP/bin

# Programs used for C code
ifeq ($(suffix $(MAIN)), .c)
CC	:= $(COMPILER)/riscv32-unknown-elf-gcc.exe
LD	:= $(CC)

# Flags used for C code
USERCCFLAGS	:= -g -O1 -ffunction-sections -fverbose-asm -fno-inline -gdwarf-2 
USERLDFLAGS	:= -Wl,--defsym=__stack_pointer$$=0x4000000 -Wl,--defsym  -Wl,JTAG_UART_BASE=0xff201000 -lm
ARCHCCFLAGS	:= -march=rv32im_zicsr -mabi=ilp32
ARCHLDFLAGS	:= -march=rv32im_zicsr -mabi=ilp32
CCFLAGS		:= -Wall -c $(USERCCFLAGS) $(ARCHCCFLAGS)
LDFLAGS		:= $(USERLDFLAGS) $(ARCHLDFLAGS)
endif

# Programs used for assembly code
ifeq ($(suffix $(MAIN)), .s)
AS	:= $(COMPILER)/riscv32-unknown-elf-as.exe
LD	:= $(COMPILER)/riscv32-unknown-elf-ld.exe
OC	:= $(COMPILER)/riscv32-unknown-elf-objcopy.exe

# Flags used for assembly code
ARCHASFLAGS	:= -march=rv32im_zicsr --gdwarf2
ARCHLDFLAGS	:= --section-start .text=0x0 --no-relax
ASFLAGS		:= $(ARCHASFLAGS)
LDFLAGS		:= $(USERLDFLAGS) $(ARCHLDFLAGS)
endif

OD	:= $(COMPILER)/riscv32-unknown-elf-objdump.exe
NM	:= $(COMPILER)/riscv32-unknown-elf-nm.exe
RM	:= /usr/bin/rm -f

# Files
OBJS		:= $(patsubst %, %.o, $(SRCS))

############################################
# GDB Macros

# Programs
GDB_SERVER	:= ash-riscv-gdb-server.exe
GDB_CLIENT	:= riscv32-unknown-elf-gdb.exe

############################################
# System Macros

# Programs
QP_PROGRAMMER	:= quartus_pgm.exe

RED_TEXT		:= @$(BASH) 'printf "\033[31m"'
GREEN_TEXT		:= @$(BASH) 'printf "\033[32m"'
CYAN_TEXT		:= @$(BASH) 'printf "\033[36m"'
YELLOW_TEXT		:= @$(BASH) 'printf "\033[33m"'
DEF_TEXT		:= @$(BASH) 'printf "\033[0m"'

############################################
# Compilation Targets

COMPILE: $(basename $(MAIN)).elf

$(basename $(MAIN)).elf: $(OBJS)
	@$(BASH) 'cd "$(CURDIR)"; $(RM) $@'
	$(CYAN_TEXT)
	@echo Linking
	@$(BASH) 'printf "$(LD)"'
	$(DEF_TEXT)
	@echo $(LDFLAGS)$(OBJS) -o $@
	@$(BASH) 'printf "\n"'
	@$(BASH) 'cd "$(CURDIR)"; $(CYGWIN_PATH); $(LD) $(LDFLAGS) $(OBJS) -o $@'

%.c.o: %.c $(HDRS)
	@$(BASH) 'cd "$(CURDIR)"; $(RM) $@'
	$(GREEN_TEXT)
	@echo Compiling
	@$(BASH) 'printf "$(CC) "'
	$(DEF_TEXT)
	@echo $(CCFLAGS) $< -o $@
	@$(BASH) 'cd "$(CURDIR)"; $(CYGWIN_PATH); $(CC) $(CCFLAGS) $< -o $@'

%.s.o: %.s $(HDRS)
	@$(BASH) 'cd "$(CURDIR)"; $(RM) $@'
	$(GREEN_TEXT)
	@echo Assembling
	@$(BASH) 'printf "$(AS) "'
	$(DEF_TEXT)
	@echo $(ASFLAGS) $< -o $@
	@$(BASH) 'cd "$(CURDIR)"; $(CYGWIN_PATH); $(AS) $(ASFLAGS) $< -o $@'

SYMBOLS: $(basename $(MAIN)).elf
	@echo $(NM) -p $<
	@$(BASH) 'cd "$(CURDIR)"; $(CYGWIN_PATH); $(NM) -p $<'

OBJDUMP: $(basename $(MAIN)).elf
	@echo $(OD) -d -S $<
	@$(BASH) 'cd "$(CURDIR)"; $(CYGWIN_PATH); $(OD) -d -S $<'

CLEAN: 
	$(RED_TEXT)
	@$(BASH) 'printf "$(RM) "'
	$(DEF_TEXT)
	@echo $(basename $(MAIN)).srec $(basename $(MAIN)).elf$(OBJS)
	@$(BASH) 'cd "$(CURDIR)"; $(RM) $(basename $(MAIN)).srec $(basename $(MAIN)).elf $(OBJS)'
	

############################################
# System Targets
#
CABLE_NAME := -c "$(shell $(BASH) '$(QP_PROGRAMMER) --auto | /usr/bin/grep "Using programming cable" | /usr/bin/sed -n "s/.*\x22\(.*\)\x22.*/\1/p"')"

JTAG_INDEX := 1		# for most boards
JTAG_INDEX_SoC := 2 # for most SoC boards
SOF_FILES := $(INSTALL)/fpgacademy/Computer_Systems

DE23-Lite := $(SOF_FILES)/DE23_Lite_NiosVg_Computer.sof
DE25-Standard := $(SOF_FILES)/DE25_Standard_NiosVg_Computer.sof
DE25-Nano := $(SOF_FILES)/DE25_Nano_NiosVg_Computer.sof
DE1-SoC := $(SOF_FILES)/DE1_SoC_NiosVg_Computer.sof
DE10-Lite := $(SOF_FILES)/DE10_Lite_NiosVg_Computer.sof
DE10-Standard := $(SOF_FILES)/DE10_Standard_NiosVg_Computer.sof
DE10-Nano := $(SOF_FILES)/DE10_Nano_NiosVg_Computer.sof

DETECT:
	$(QP_PROGRAMMER) --auto

DE23-Lite:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE23-Lite)@$(JTAG_INDEX)"
	
DE25-Standard:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE25-Standard)@$(JTAG_INDEX)"

DE1-SoC:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE1-SoC)@$(JTAG_INDEX_SoC)"

DE10-Lite:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE10-Lite)@$(JTAG_INDEX)"
	
DE10-Standard:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE10-Standard)@$(JTAG_INDEX_SoC)"

DE10-Nano:
	$(QP_PROGRAMMER) $(CABLE_NAME) -m jtag -o "P;$(DE10-Nano)@$(JTAG_INDEX_SoC)"

TERMINAL:
	nios2-terminal.exe --instance 0

############################################
# GDB Targets

GDB_SERVER: 
	$(GDB_SERVER) --device 02D120DD --gdb-port 2454 --instance 1 --probe-type USB-Blaster-2 --transport-type jtag --auto-detect true

GDB_CLIENT: 
	$(GDB_CLIENT) -silent -ex "target remote:2454" -iex "set $$mstatus=0" -iex "set $$mtvec=0" -iex "set $$mie=0" -ex "load" -ex "set $$pc=_start" -ex "info reg pc" "$(basename $(MAIN)).elf"

############################################
# EXTRAS

.SILENT: SYMBOLS OBJDUMP

