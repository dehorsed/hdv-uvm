// Copyright Daniil Kanelsky.
// Licensed under the Apache License, Version 2.0
// SPDX-License-Identifier: Apache-2.0

class hdv_scoreboard #(type ITEM_T     = uvm_sequence_item,
                       type RSP_ITEM_T = ITEM_T,
                       type CFG_T      = hdv_env_cfg) extends uvm_scoreboard;

  `uvm_component_param_utils(hdv_scoreboard #(ITEM_T, RSP_ITEM_T, CFG_T))

  // Requests (expected)
  uvm_tlm_analysis_fifo #(ITEM_T)     req_fifo;
  // Responses (actual)
  uvm_tlm_analysis_fifo #(RSP_ITEM_T) rsp_fifo;

  CFG_T cfg;

  // Expected queue
  ITEM_T exp_q[$];

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    req_fifo = new("req_fifo", this);
    rsp_fifo = new("rsp_fifo", this);

    if (!uvm_config_db#(CFG_T)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(`gfn, "Failed to get cfg from uvm_config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      collect_expected();
      collect_actual();
    join_none
  endtask

  task collect_expected();
    ITEM_T item, clone;

    forever begin
      req_fifo.get(item);

      $cast(clone, item.clone());
      exp_q.push_back(clone);

      `uvm_info("SCB_EXP",
        $sformatf("Expected item queued:\n%s", clone.sprint()),
        UVM_HIGH)
    end
  endtask

  task collect_actual();
    RSP_ITEM_T act;
    ITEM_T     exp;

    forever begin
      rsp_fifo.get(act);

      if (exp_q.size() == 0) begin
        `uvm_error("SCB",
          $sformatf("Response received with no expected item:\n%s",
                    act.sprint()))
        continue;
      end

      exp = exp_q.pop_front();

      if (!compare(exp, act)) begin
        `uvm_error("SCB_MISMATCH",
          $sformatf("Mismatch detected\nEXP:\n%s\nACT:\n%s",
                    exp.sprint(), act.sprint()))
      end
      else begin
        `uvm_info("SCB_MATCH", "Transaction matched", UVM_MEDIUM)
      end
    end
  endtask

  virtual function bit compare(ITEM_T exp, RSP_ITEM_T act);
    return exp.compare(act);
  endfunction

  // End-of-test checks
  function void check_phase(uvm_phase phase);
    if (exp_q.size() != 0) begin
      `uvm_error("SCB",
        $sformatf("Scoreboard not empty at end of test: %0d items left",
                  exp_q.size()))
    end
  endfunction

endclass
