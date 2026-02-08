// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_monitor #(type ITEM_T     = uvm_sequence_item,
                    type REQ_ITEM_T = ITEM_T,
                    type RSP_ITEM_T = ITEM_T,
                    type CFG_T      = hdv_agent_cfg,
                    type COV_T      = hdv_agent_cov) extends uvm_monitor;
  `uvm_component_param_utils(hdv_monitor #(ITEM_T, REQ_ITEM_T, RSP_ITEM_T, CFG_T, COV_T))

  CFG_T cfg;
  COV_T cov;

  // Analysis port for the collected transfer.
  uvm_analysis_port #(ITEM_T) analysis_port;

  // item will be sent to this port for seq when req phase is done (last is set)
  uvm_analysis_port #(REQ_ITEM_T) req_analysis_port;
  // item will be sent to this port for seq when rsp phase is done (rsp_done is set)
  uvm_analysis_port #(RSP_ITEM_T) rsp_analysis_port;

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);
    req_analysis_port = new("req_analysis_port", this);
    rsp_analysis_port = new("rsp_analysis_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      collect_trans();
    join
  endtask

  // collect transactions forever
  virtual protected task collect_trans();
    // Empty - to be overridden in the child class
  endtask

endclass
