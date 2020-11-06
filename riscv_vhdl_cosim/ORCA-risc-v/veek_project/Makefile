all: vblox1.sof

QSYS_FILE=vblox1.qsys
QPF_FILE=vblox1.qpf
QIP_FILE=vblox1/synthesis/vblox1.qip
OUTPUT_DIR=output_files/
MAP_RPT_FILE=$(OUTPUT_DIR)vblox1.map.rpt
FIT_RPT_FILE=$(OUTPUT_DIR)vblox1.fit.rpt
ASM_RPT_FILE=$(OUTPUT_DIR)vblox1.asm.rpt
MIF_RPT_FILE=$(OUTPUT_DIR)vblox1.mif_update.rpt
STA_RPT_FILE=$(OUTPUT_DIR)vblox1.sta.rpt


DEVICE_FAMILY=$(shell grep deviceFamily $(QSYS_FILE) | head -1 | sed 's/.*value="\(.*\)".*/\1/')
VHDL_FILES=$(wildcard ../*.vhd)
VHDL_SUBMODULE_FILES=$(addprefix vblox1/synthesis/submodules/,$(notdir $(VHDL_FILES)))
TOP_LEVEL_FILES=$(wildcard *.vhd)



-include config.mk

$(QSYS_FILE):$(wildcard config.mk)
ifdef BRANCH_PREDICTION
	sed -i 's|parameter name="BRANCH_PREDICTION" value=".*" />|parameter name="BRANCH_PREDICTION" value=$(BRANCH_PREDICTION) />|' $(QSYS_FILE)
endif
ifdef BTB_SIZE
	sed -i 's|parameter name="BTB_SIZE" value=".*" />|parameter name="BTB_SIZE" value=$(BTB_SIZE) />|' $(QSYS_FILE)
endif
ifdef DIVIDE_ENABLE
	sed -i 's|parameter name="DIVIDE_ENABLE" value=".*" />|parameter name="DIVIDE_ENABLE" value=$(DIVIDE_ENABLE) />|' $(QSYS_FILE)
endif
ifdef INCLUDE_COUNTERS
	sed -i 's|parameter name="INCLUDE_COUNTERS" value=".*" />|parameter name="INCLUDE_COUNTERS" value=$(INCLUDE_COUNTERS) />|' $(QSYS_FILE)
endif
ifdef MULTIPLY_ENABLE
	sed -i 's|parameter name="MULTIPLY_ENABLE" value=".*" />|parameter name="MULTIPLY_ENABLE" value=$(MULTIPLY_ENABLE) />|' $(QSYS_FILE)
endif
ifdef PIPELINE_STAGES
	sed -i 's|parameter name="PIPELINE_STAGES" value=".*" />|parameter name="PIPELINE_STAGES" value=$(PIPELINE_STAGES) />|' $(QSYS_FILE)
endif
ifdef SHIFTER_SINGLE_CYCLE
	sed -i 's|parameter name="SHIFTER_SINGLE_CYCLE" value=".*" />|parameter name="SHIFTER_SINGLE_CYCLE" value=$(SHIFTER_SINGLE_CYCLE) />|' $(QSYS_FILE)
endif
ifdef FORWARD_ALU_ONLY
	sed -i 's|parameter name="FORWARD_ALU_ONLY" value=".*" />|parameter name="FORWARD_ALU_ONLY" value=$(FORWARD_ALU_ONLY) />|' $(QSYS_FILE)
endif

$(QIP_FILE):$(QSYS_FILE)
	qsys-generate --synthesis=VHDL vblox1.qsys 2>&1 | tee ./vblox1.qsys.log

$(VHDL_SUBMODULE_FILES): vblox1/synthesis/submodules/% : ../%
	cp $^ $@

HEX_FILE=$(wildcard test.hex)

$(MAP_RPT_FILE) : $(QIP_FILE) $(VHDL_SUBMODULE_FILES) $(TOP_LEVEL_FILES)
	quartus_map $(QPF_FILE)
$(FIT_RPT_FILE) : $(MAP_RPT_FILE)
	quartus_fit $(QPF_FILE)
$(STA_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_sta $(QPF_FILE)
$(MIF_RPT_FILE) : $(STA_RPT_FILE) $(HEX_FILE)
	quartus_cdb --update_mif $(QPF_FILE)
$(ASM_RPT_FILE) : $(MIF_RPT_FILE)
	quartus_asm $(QPF_FILE)

vblox1.sof: $(ASM_RPT_FILE)
	cp $(OUTPUT_DIR)/$@ $@

qip: $(QIP_FILE)
map: $(MAP_RPT_FILE)
fit: $(FIT_RPT_FILE)
mif: $(MIF_RPT_FILE)
asm: $(ASM_RPT_FILE)
sta: $(STA_RPT_FILE)

.phony: all clean qip map fit mif asm sta pgm

clean:
	rm -rf vblox1/ $(OUTPUT_DIR)

pgm: vblox1.sof
	quartus_pgm -m JTAG -o P\;$^
