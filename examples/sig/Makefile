TB_TOP    := tbench_top
TEST_NAME ?= sig_model_test
OUT_DIR   ?= out
SIM_NAME  := $(TB_TOP)
RTL_SRC   := $(shell find *.sv)
RTL_HDR   := $(shell find *.svh)
WORK      := work

VERILATOR ?= verilator
VLIB ?= vlib
VLOG ?= vlog
VSIM ?= vsim

PWD := $(shell pwd)

all: run
sim: run

lint:
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TB_TOP) -I$(UVM_HOME) -I$(PWD) -DUVM_NO_DPI -Wno-fatal -Wall -Wpedantic --lint-only --timing $(UVM_HOME)/uvm_pkg.sv $(RTL_SRC)

$(OUT_DIR)/questa/lib:
	@mkdir -p $(OUT_DIR)/questa
	$(VLIB) $@
	@touch $@

$(OUT_DIR)/questa/log: $(OUT_DIR)/questa/lib $(RTL_SRC) $(RTL_HDR)
	$(VLOG) -sv -work $< $(RTL_SRC)
	@touch $@

run: $(OUT_DIR)/questa/log
	$(VSIM) -c -vopt -do "run -all; quit" $(OUT_DIR)/questa/$(WORK).$(TB_TOP) +UVM_TESTNAME=sig_model_test

clean:
	rm -rf out/*.*

distclean:
	rm -rf out

.PHONY: all run sim clean distclean
