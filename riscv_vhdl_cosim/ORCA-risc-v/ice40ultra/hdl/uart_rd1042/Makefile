#Makefile for quick testing for syntax errors and such
#Builds all the HDL and starts the simulation to ensure no assertions thrown

#Assume top level entity has same name as last source file in Filelist
TOP_LEVEL=$(shell tail -1 Filelist | sed 's/\..*//g')
VCOM=vcom
VCOMFLAGS=-pedanticerrors

SUBDIR_FILELISTS=$(shell find -mindepth 2 -name 'Filelist')
SOURCES=$(shell for filelist in $(SUBDIR_FILELISTS); do subdir=$$(dirname $$filelist | sed "s|^\./||g"); grep -v \\\# $$filelist | sed "s|^|$${subdir}/|g"; done)
#for filelist in $(SUBDIR_FILELISTS); do grep -v \\\# $$filelist | sed "s/^/uart_core\//g"; done)
SOURCES+=$(shell grep -v \\\# 'Filelist')

#_primary.dat seems like the file to test for in the library
COMPILED_SOURCES=$(patsubst %.vhd,work/%/_primary.dat,$(SOURCES))

#Always just clean and remake everything.
transcript: clean $(COMPILED_SOURCES)
	vsim -c work.$(TOP_LEVEL) -do "run 1ns; exit"

work/%/_primary.dat: %.vhd
	@if [ ! -e work ]; then vlib work; fi
	$(VCOM) $(VCOMFLAGS) $<

clean:
	@rm -f *~
#Get ignored files from .gitignore (top level only), delete.
	@while read line || [[ -n $${line} ]]; do \
		if [[ $${line} =~ ^/.* ]]; then \
			line=$$(echo $${line} | sed 's/^\///g'); \
			rm -rf $${line}; \
		fi; \
	done < .gitignore
