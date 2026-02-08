// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class hdv_test #(type CFG_T = hdv_env_cfg,
                 type ENV_T = hdv_env,
                 type SEQUENCE_T) extends uvm_test;
  `uvm_component_param_utils(hdv_test #(CFG_T, ENV_T))

  ENV_T             env;
  CFG_T             cfg;

  `uvm_component_new

endclass
