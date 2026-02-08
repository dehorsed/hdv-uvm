// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

// A base class for coverage collection.

class hdv_env_cov #(type ITEM_T = uvm_sequence_item,
                    type CFG_T  = hdv_env_cfg) extends uvm_subscriber#(ITEM_T);
  `uvm_component_param_utils(hdv_env_cov #(ITEM_T, CFG_T))

  CFG_T cfg;

  `uvm_component_new

endclass
