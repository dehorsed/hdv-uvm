// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_driver #(type ITEM_T     = uvm_sequence_item,
                   type CFG_T      = hdv_agent_cfg,
                   type RSP_ITEM_T = ITEM_T)
  extends uvm_driver #(.REQ(ITEM_T), .RSP(RSP_ITEM_T));

  `uvm_component_param_utils(hdv_driver #(ITEM_T, CFG_T, RSP_ITEM_T))

  bit   under_reset;
  CFG_T cfg;

  `uvm_component_new

  virtual task run_phase(uvm_phase phase);
    ITEM_T req;

    super.run_phase(phase);
    fork
      forever begin
        @(negedge cfg.vif.rst_n);
        under_reset = 1;

        reset_signals();

        @(posedge cfg.vif.rst_n);
        under_reset = 0;
      end
      forever begin
        seq_item_port.get_next_item(req);

        // Wait until reset end
        wait(!under_reset);

        drive_trans(req);

        seq_item_port.item_done();
      end
    join_none
  endtask

  // reset signals
  virtual task reset_signals();
    // Empty - to be populated in child class
  endtask

  // drive trans received from sequencer
  virtual task drive_trans(ITEM_T req);
    // Empty - to be populated in child class
  endtask

endclass
