// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_sequence #(type REQ         = uvm_sequence_item,
                     type RSP         = REQ,
                     type CFG_T       = hdv_agent_cfg,
                     type SEQUENCER_T = hdv_sequencer) extends uvm_sequence#(REQ, RSP);
  `uvm_object_param_utils(hdv_sequence #(REQ, RSP, CFG_T, SEQUENCER_T))
  `uvm_declare_p_sequencer(SEQUENCER_T)

  CFG_T cfg;

  `uvm_object_new

  task pre_start();
    super.pre_start();
    cfg = p_sequencer.cfg;
  endtask

  task body();
    `uvm_fatal(`gtn, "Need to override this when you extend from this class!")
  endtask : body

endclass
