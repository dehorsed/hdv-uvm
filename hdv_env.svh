// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_env #(type CFG_T               = hdv_env_cfg,
                type SCOREBOARD_T        = hdv_scoreboard,
                type COV_T               = hdv_env_cov) extends uvm_env;
  `uvm_component_param_utils(hdv_env #(CFG_T, SCOREBOARD_T, COV_T))

  CFG_T                      cfg;
  SCOREBOARD_T               scoreboard;
  COV_T                      cov;

  `uvm_component_new

  virtual function void build_phase(uvm_phase phase);
    string default_ral_name;
    super.build_phase(phase);
    // get hdv_env_cfg object from uvm_config_db
    if (!uvm_config_db#(CFG_T)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(`gfn, $sformatf("failed to get %s from uvm_config_db", cfg.get_type_name()))
    end

    // create components
    if (cfg.en_cov) begin
      cov = COV_T::type_id::create("cov", this);
      cov.cfg = cfg;
    end

    scoreboard = SCOREBOARD_T::type_id::create("scoreboard", this);
    scoreboard.cfg = cfg;
    scoreboard.cov = cov;
  endfunction

endclass
