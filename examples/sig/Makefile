TB_TOP   := sig_tb
OUT_DIR  ?= out
SIM_NAME := $(TB_TOP)
RTL_SRC  := $(shell find *.sv)
RTL_HDR  := $(shell find *.svh)

VERILATOR ?= verilator
VERILATOR_FLAGS ?= -j 0 -O3

PWD := $(shell pwd)

all: run

$(OUT_DIR)/$(SIM_NAME): $(RTL_SRC) $(RTL_HDR)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TB_TOP) -I$(UVM_HOME)/src -I../.. -I$(PWD) -DUVM_NO_DPI -Wno-fatal --Mdir $(OUT_DIR) --binary -o $(SIM_NAME) $(UVM_HOME)/src/uvm_pkg.sv ../../hdv_pkg.sv $(RTL_SRC)

lint:
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TB_TOP) -I$(UVM_HOME)/src -I../.. -I$(PWD) -DUVM_NO_DPI -Wno-fatal -Wall -Wpedantic --lint-only --timing $(UVM_HOME)/src/uvm_pkg.sv ../../hdv_pkg.sv $(RTL_SRC)

run: $(OUT_DIR)/$(SIM_NAME)
	$(OUT_DIR)/$(SIM_NAME)

clean:
	rm -rf out/*.*

distclean:
	rm -rf out