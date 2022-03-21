# This Makefile calls the Makefiles for all tutorials
# It was run in Ubuntu 20.04 WSL with the package texlive-full on Windows 10
#
# Targets:
#
# 1) 
# Name:              default
# Command Line Call: make
# Description:       Build all the Tutorial PDFs from their Latex source
#
# 2)
# Name:              release
# Command Line Call: make release
# Description:       Copy all the PDFs and Design File ZIPs to a release directory
#
# 3)
# Name:              clean
# Command Line Call: make clean
# Description:       Clean up the temporary files from all the Tutorials directories
#
#
# To build and release individual tutorials, navigate to the specific tutorial's
# directory and run:
# make -f Tutorials.mk
# make -f Tutorials.mk release
# make -f Tutorials.mk clean
#


MAKEFILES = $(dir $(wildcard */*/Tutorials.mk)) $(dir $(wildcard */*/*/Tutorials.mk))


default: $(MAKEFILES)

$(MAKEFILES):
	$(MAKE) -C $@ -f Tutorials.mk


release: mk_release_dir $(addprefix release.,$(MAKEFILES))

mk_release_dir:
	rm -rf ./release
	mkdir ./release

$(addprefix release.,$(MAKEFILES)): release.%:
	-$(MAKE) -C $* -f Tutorials.mk -s release


clean: $(addprefix clean.,$(MAKEFILES))

$(addprefix clean.,$(MAKEFILES)): clean.%:
	-$(MAKE) -C $* -f Tutorials.mk -s clean

.PHONY: default $(MAKEFILES) release mk_release_dir $(addprefix release.,$(MAKEFILES)) clean $(addprefix clean.,$(MAKEFILES))
