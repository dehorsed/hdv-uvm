// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

// A base environment configuration that is used for all OpenTitan environments.

class hdv_env_cfg extends uvm_object;

  // True if the environment is active (and thus drives sequences items to the dut). This is the
  // default.
  bit is_active = 1;

  // True if the scoreboard should be enabled. If it is false, the scoreboard still runs, but should
  // ignore its checks.
  bit en_scb = 1;

  // Enable functional coverage collection. This causes monitors and scoreboards to collect coverage
  // (through a hdv_env_cov object).
  bit en_cov = 0;

  `uvm_object_utils_begin(hdv_env_cfg)
    `uvm_field_int              (is_active,       UVM_DEFAULT)
    `uvm_field_int              (en_scb,          UVM_DEFAULT)
    `uvm_field_int              (en_cov,          UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
endclass
