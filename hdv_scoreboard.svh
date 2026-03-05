// Copyright Daniil Kanelsky.
// Licensed under the Apache License, Version 2.0
// SPDX-License-Identifier: Apache-2.0

class hdv_scoreboard #(
  type CFG_T = hdv_env_cfg
) extends uvm_scoreboard;
  `uvm_component_param_utils(hdv_scoreboard#(CFG_T))

  CFG_T cfg;

  `uvm_component_new

endclass
