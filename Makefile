VERILATOR ?= verilator
UVM_HOME ?= /usr/share/1800.2-2017-1.0

VLIB ?= vlib
VLOG ?= vlog
VSIM ?= vsim

all: lint

lint:
	$(VERILATOR) -sv -I$(UVM_HOME)/src -DUVM_NO_DPI -Wall -Wpedantic -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND --lint-only $(UVM_HOME)/src/uvm_pkg.sv hdv_pkg.sv

format:
	

example:
	$(VLIB) work
	$(VLOG) hdv_pkg.sv examples/sig/*.sv
	$(VSIM) -c -vopt -do "run -all; quit" work.tbench_top +UVM_TESTNAME=sig_model_test

.PHONY: lint
