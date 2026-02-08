// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_agent_cfg extends uvm_object;

  bit         en_cov    = 1'b1;   // enable coverage

  // indicate if these FIFO and ports exist or not
  bit         has_req_fifo = 1'b0;
  bit         has_rsp_fifo = 1'b0;

  // Indicates that the interface is under reset. The derived monitor detects and maintains it.
  bit in_reset;

  `uvm_object_utils_begin(hdv_agent_cfg)
    `uvm_field_int (en_cov,       UVM_DEFAULT)
    `uvm_field_int (has_req_fifo, UVM_DEFAULT)
    `uvm_field_int (has_rsp_fifo, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new

endclass
