// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_agent #(type CFG_T            = hdv_agent_cfg,
                  type DRIVER_T         = hdv_driver,
                  type SEQUENCER_T      = hdv_sequencer,
                  type MONITOR_T        = hdv_monitor,
                  type COV_T            = hdv_agent_cov) extends uvm_agent;

  `uvm_component_param_utils(hdv_agent #(CFG_T, DRIVER_T,
                                         SEQUENCER_T, MONITOR_T, COV_T))

  CFG_T       cfg;
  COV_T       cov;
  DRIVER_T    driver;
  SEQUENCER_T sequencer;
  MONITOR_T   monitor;

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get CFG_T object from uvm_config_db
    if (!uvm_config_db#(CFG_T)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(`gfn, $sformatf("failed to get %s from uvm_config_db", cfg.get_type_name()))
    end
    `uvm_info(`gfn, $sformatf("\n%0s", cfg.sprint()), UVM_HIGH)

    // create components
    if (cfg.en_cov) begin
      cov = COV_T ::type_id::create("cov", this);
      cov.cfg = cfg;
    end

    monitor = MONITOR_T::type_id::create("monitor", this);
    monitor.cfg = cfg;
    monitor.cov = cov;

    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = SEQUENCER_T::type_id::create("sequencer", this);
      sequencer.cfg = cfg;

      driver = DRIVER_T::type_id::create("driver", this);
      driver.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
    if (cfg.has_req_fifo) begin
      monitor.req_analysis_port.connect(sequencer.req_analysis_fifo.analysis_export);
    end
    if (cfg.has_rsp_fifo) begin
      monitor.rsp_analysis_port.connect(sequencer.rsp_analysis_fifo.analysis_export);
    end
  endfunction

endclass
