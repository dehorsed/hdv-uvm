// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_agent_cov #(type ITEM_T = uvm_sequence_item,
                      type CFG_T  = hdv_agent_cfg) extends uvm_subscriber#(ITEM_T);
  `uvm_component_param_utils(hdv_agent_cov #(ITEM_T, CFG_T))

  CFG_T cfg;

  `uvm_component_new

endclass
