# This Makefile compiles the tutorial in this folder

TUTROOT = ../..
TEXFILES = DevCloud.tex
DESIGNFILESZIP = 

include $(TUTROOT)/Common/Scripts/Makefile.common

test:
	@echo the path is $(TUTROOT)
