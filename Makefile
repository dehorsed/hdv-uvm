VERILATOR ?= verilator
UVM_HOME ?= /usr/share/1800.2-2017-1.0

all: lint

lint:
	$(VERILATOR) -sv -I$(UVM_HOME)/src -DUVM_NO_DPI -Wall -Wpedantic -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND --lint-only $(UVM_HOME)/src/uvm_pkg.sv hdv_pkg.sv

.PHONY: lint
