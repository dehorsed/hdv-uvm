// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class hdv_test #(type CFG_T = hdv_env_cfg,
                 type ENV_T = hdv_env,
                 type SEQUENCE_T = hdv_sequence) extends uvm_test;
  `uvm_component_param_utils(hdv_test #(CFG_T, ENV_T))

  ENV_T             env;
  CFG_T             cfg;
  SEQUENCE_T        seq;

  `uvm_component_new
  
  virtual function void build_phase(uvm_phase phase);
`ifdef VERILATOR
    uvm_object obj;
`endif

    super.build_phase(phase);
    env = ENV_T::type_id::create("env", this);
`ifdef VERILATOR
    obj = SEQUENCE_T::type_id::create("seq");
    if (!$cast(seq, obj)) begin
      `uvm_fatal("SEQ", "Factory returned wrong sequence type");
    end
`else
    seq = SEQUENCE_T::type_id::create("seq");
`endif
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.sig_agnt_d.sequencer);
    phase.drop_objection(this);
  endtask : run_phase

endclass
