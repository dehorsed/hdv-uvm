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
// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_driver #(type ITEM_T     = uvm_sequence_item,
                   type CFG_T      = hdv_agent_cfg,
                   type RSP_ITEM_T = ITEM_T)
  extends uvm_driver #(.REQ(ITEM_T), .RSP(RSP_ITEM_T));

  `uvm_component_param_utils(hdv_driver #(ITEM_T, CFG_T, RSP_ITEM_T))

  bit   under_reset;
  CFG_T cfg;

  `uvm_component_new

  virtual task run_phase(uvm_phase phase);
    ITEM_T req;

    super.run_phase(phase);
    fork
      forever begin
        @(negedge cfg.vif.rst_n);
        under_reset = 1;

        reset_signals();

        @(posedge cfg.vif.rst_n);
        under_reset = 0;
      end
      forever begin
        seq_item_port.get_next_item(req);

        // Wait until reset end
        wait(!under_reset);

        drive_trans(req);

        seq_item_port.item_done();
      end
    join_none
  endtask

  // reset signals
  virtual task reset_signals();
    // Empty - to be populated in child class
  endtask

  // drive trans received from sequencer
  virtual task drive_trans(ITEM_T req);
    // Empty - to be populated in child class
  endtask

endclass
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
// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

`ifdef UVM
  `include "uvm_macros.svh"
`endif

// UVM speficic macros
`ifndef gfn
`ifdef UVM
  // verilog_lint: waive macro-name-style
  `define gfn get_full_name()
`else
  // verilog_lint: waive macro-name-style
  `define gfn $sformatf("%m")
`endif
`endif

`ifndef gtn
  // verilog_lint: waive macro-name-style
  `define gtn get_type_name()
`endif

`ifndef gn
  // verilog_lint: waive macro-name-style
  `define gn get_name()
`endif

`ifndef gmv
  // verilog_lint: waive macro-name-style
  `define gmv(csr) csr.get_mirrored_value()
`endif

// cast base class obj holding extended class handle to extended class handle;
// throw error if cast fails
`ifndef downcast
  // verilog_lint: waive macro-name-style
  `define downcast(EXT_, BASE_, MSG_="", SEV_=fatal, ID_=`gfn) \
    begin \
      if (!$cast(EXT_, BASE_)) begin \
        `dv_``SEV_($sformatf({"Cast failed: base class variable %0s ", \
                              "does not hold extended class %0s handle %s"}, \
                              `"BASE_`", `"EXT_`", MSG_), ID_) \
      end \
    end
`endif

// Note, UVM provides a macro `uvm_new_func -- which only applies to uvm_components
`ifndef uvm_object_new
  `define uvm_object_new \
    function new (string name=""); \
      super.new(name); \
    endfunction : new
`endif

`ifndef uvm_create_obj
  `define uvm_create_obj(_type_name_, _inst_name_) \
    _inst_name_ = _type_name_::type_id::create(`"_inst_name_`");
`endif

`ifndef uvm_component_new
  `define uvm_component_new \
    function new (string name, uvm_component parent); \
      super.new(name, parent); \
    endfunction : new
`endif

`ifndef uvm_create_comp
  `define uvm_create_comp(_type_name_, _inst_name_) \
    _inst_name_ = _type_name_::type_id::create(`"_inst_name_`", this);
`endif

// Convert arbitrary text / expression to string.
`ifndef DV_STRINGIFY
  `define DV_STRINGIFY(I_) `"I_`"
`endif

`ifndef DUT_HIER_STR
  `define DUT_HIER_STR `DV_STRINGIFY(`DUT_HIER)
`endif

// Common check macros used by DV_CHECK error and fatal macros.
// Note: Should not be called by user code
`ifndef DV_CHECK
  `define DV_CHECK(T_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if (T_) ; else begin \
        `dv_``SEV_($sformatf("Check failed (%s) %s ", `"T_`", MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_EQ
  `define DV_CHECK_EQ(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) == (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s == %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_NE
  `define DV_CHECK_NE(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) != (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s != %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_CASE_EQ
  `define DV_CHECK_CASE_EQ(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) === (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s === %s (0x%0h [%0b] vs 0x%0h [%0b]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_CASE_NE
  `define DV_CHECK_CASE_NE(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) !== (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s !== %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_LT
  `define DV_CHECK_LT(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) < (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s < %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_GT
  `define DV_CHECK_GT(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) > (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s > %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_LE
  `define DV_CHECK_LE(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) <= (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s <= %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_GE
  `define DV_CHECK_GE(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) >= (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed %s >= %s (%0d [0x%0h] vs %0d [0x%0h]) %s", \
                             `"ACT_`", `"EXP_`", ACT_, ACT_, EXP_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_STREQ
  `define DV_CHECK_STREQ(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) == (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed \"%s\" == \"%s\" %s", ACT_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_STRNE
  `define DV_CHECK_STRNE(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      if ((ACT_) != (EXP_)) ; else begin \
        `dv_``SEV_($sformatf("Check failed \"%s\" != \"%s\" %s", ACT_, EXP_, MSG_), ID_) \
      end \
    end
`endif

`ifndef DV_CHECK_Q_EQ
  `define DV_CHECK_Q_EQ(ACT_, EXP_, MSG_="", SEV_=error, ID_=`gfn) \
    begin \
      `DV_CHECK_EQ(ACT_.size(), EXP_.size(), MSG_, SEV_, ID_) \
      foreach (ACT_[i]) begin \
        `DV_CHECK_EQ(ACT_[i], EXP_[i], $sformatf("for i = %0d %s", i, MSG_), SEV_, ID_) \
      end \
    end
`endif

// Fatal version of the checks
`ifndef DV_CHECK_FATAL
  `define DV_CHECK_FATAL(T_, MSG_="", ID_=`gfn) \
    `DV_CHECK(T_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_EQ_FATAL
  `define DV_CHECK_EQ_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_EQ(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_NE_FATAL
  `define DV_CHECK_NE_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_NE(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_LT_FATAL
  `define DV_CHECK_LT_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_LT(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_GT_FATAL
  `define DV_CHECK_GT_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_GT(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_LE_FATAL
  `define DV_CHECK_LE_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_LE(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_GE_FATAL
  `define DV_CHECK_GE_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_GE(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_STREQ_FATAL
  `define DV_CHECK_STREQ_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_STREQ(ACT_, EXP_, MSG_, fatal, ID_)
`endif

`ifndef DV_CHECK_STRNE_FATAL
  `define DV_CHECK_STRNE_FATAL(ACT_, EXP_, MSG_="", ID_=`gfn) \
    `DV_CHECK_STRNE(ACT_, EXP_, MSG_, fatal, ID_)
`endif

// Shorthand for common foo.randomize() + fatal check
`ifndef DV_CHECK_RANDOMIZE_FATAL
  `define DV_CHECK_RANDOMIZE_FATAL(VAR_, MSG_="Randomization failed!", ID_=`gfn) \
    `DV_CHECK_FATAL(VAR_.randomize(), MSG_, ID_)
`endif

// Shorthand for common foo.randomize() with { } + fatal check
`ifndef DV_CHECK_RANDOMIZE_WITH_FATAL
  `define DV_CHECK_RANDOMIZE_WITH_FATAL(VAR_, WITH_C_, MSG_="Randomization failed!", ID_=`gfn) \
    `DV_CHECK_FATAL(VAR_.randomize() with {WITH_C_}, MSG_, ID_)
`endif

// Shorthand for common std::randomize(foo) + fatal check
`ifndef DV_CHECK_STD_RANDOMIZE_FATAL
  `define DV_CHECK_STD_RANDOMIZE_FATAL(VAR_, MSG_="Randomization failed!", ID_=`gfn) \
    `DV_CHECK_FATAL(std::randomize(VAR_), MSG_, ID_)
`endif

// Shorthand for common std::randomize(foo) with { } + fatal check
`ifndef DV_CHECK_STD_RANDOMIZE_WITH_FATAL
  `define DV_CHECK_STD_RANDOMIZE_WITH_FATAL(VAR_, WITH_C_, MSG_="Randomization failed!",ID_=`gfn) \
    `DV_CHECK_FATAL(std::randomize(VAR_) with {WITH_C_}, MSG_, ID_)
`endif

// Shorthand for common cls_inst.randomize(member) + fatal check
// Randomizes a specific member of a class instance.
`ifndef DV_CHECK_MEMBER_RANDOMIZE_FATAL
  `define DV_CHECK_MEMBER_RANDOMIZE_FATAL(VAR_, CLS_INST_=this, MSG_="Randomization failed!", ID_=`gfn) \
    `DV_CHECK_FATAL(CLS_INST_.randomize(VAR_), MSG_, ID_)
`endif

// Shorthand for common cls_inst.randomize(member) with { } + fatal check
// Randomizes a specific member of a class instance with inline constraints.
`ifndef DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL
  `define DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL(VAR_, C_, CLS_INST_=this, MSG_="Randomization failed!", ID_=`gfn) \
    `DV_CHECK_FATAL(CLS_INST_.randomize(VAR_) with {C_}, MSG_, ID_)
`endif

// print static/dynamic 1d array or queue
`ifndef DV_PRINT_ARR_CONTENTS
`define DV_PRINT_ARR_CONTENTS(ARR_, V_=uvm_pkg::UVM_MEDIUM, ID_=`gfn) \
  begin \
    foreach (ARR_[i]) begin \
      `dv_info($sformatf("%s[%0d] = %0d (0x%0h)", `"ARR_`", i, ARR_[i], ARR_[i]), V_, ID_) \
    end \
  end
`endif

// print non-empty tlm FIFOs that were uncompared at end of test
`ifndef DV_EOT_PRINT_TLM_FIFO_CONTENTS
`define DV_EOT_PRINT_TLM_FIFO_CONTENTS(TYP_, FIFO_, SEV_=error, ID_=`gfn)                          \
  forever begin                                                                                    \
    TYP_ item;                                                                                     \
    int res = FIFO_.try_get(item);                                                                 \
    if (res == 0) break;                                                                           \
    if (res < 0) `dv_fatal($sformatf("Cannot read item from %s (type mismatch)", `"FIFO_`"), ID_)  \
    `dv_``SEV_($sformatf("%s item uncompared:\n%s", `"FIFO_`", item.sprint()), ID_)                \
  end
`endif

// print non-empty tlm FIFOs that were uncompared at end of test
`ifndef DV_EOT_PRINT_TLM_FIFO_ARR_CONTENTS
`define DV_EOT_PRINT_TLM_FIFO_ARR_CONTENTS(TYP_, FIFO_, SEV_=error, ID_=`gfn) \
  begin \
    foreach (FIFO_[i]) begin \
      while (!FIFO_[i].is_empty()) begin \
        TYP_ item; \
        void'(FIFO_[i].try_get(item)); \
        `dv_``SEV_($sformatf("%s[%0d] item uncompared:\n%s", `"FIFO_`", i, item.sprint()), ID_) \
      end \
    end \
  end
`endif

// print non-empty tlm FIFOs that were uncompared at end of test
`ifndef DV_EOT_PRINT_Q_CONTENTS
`define DV_EOT_PRINT_Q_CONTENTS(TYP_, Q_, SEV_=error, ID_=`gfn) \
  begin \
    while (Q_.size() != 0) begin \
      TYP_ item = Q_.pop_front(); \
      `dv_``SEV_($sformatf("%s item uncompared:\n%s", `"Q_`", item.sprint()), ID_) \
    end \
  end
`endif

// print non-empty tlm FIFOs that were uncompared at end of test
`ifndef DV_EOT_PRINT_Q_ARR_CONTENTS
`define DV_EOT_PRINT_Q_ARR_CONTENTS(TYP_, Q_, SEV_=error, ID_=`gfn) \
  begin \
    foreach (Q_[i]) begin \
      while (Q_[i].size() != 0) begin \
        TYP_ item = Q_[i].pop_front(); \
        `dv_``SEV_($sformatf("%s[%0d] item uncompared:\n%s", `"Q_`", i, item.sprint()), ID_) \
      end \
    end \
  end
`endif

// check for non-empty mailbox and print items that were uncompared at end of test
`ifndef DV_EOT_PRINT_MAILBOX_CONTENTS
`define DV_EOT_PRINT_MAILBOX_CONTENTS(TYP_, MAILBOX_, SEV_=error, ID_=`gfn) \
  begin \
    while (MAILBOX_.num() != 0) begin \
      TYP_ item; \
      void'(MAILBOX_.try_get(item)); \
      `dv_``SEV_($sformatf("%s item uncompared:\n%s", `"MAILBOX_`", item.sprint()), ID_) \
    end \
  end
`endif

// get parity - implemented as a macro so that it can be invoked in constraints as well
`ifndef GET_PARITY
  `define GET_PARITY(val, odd=0) (^val ^ odd)
`endif

// Wait for a statement but stop early if the EXIT statement completes.
//
// Example usage:
//
//    `DV_SPINWAIT_EXIT(do_something_time_consuming();,
//                      wait(stop_now_flag);,
//                      "The stop flag was set when we were working")
`ifndef DV_SPINWAIT_EXIT
`define DV_SPINWAIT_EXIT(WAIT_, EXIT_, MSG_ = "exit condition occurred!", ID_ =`gfn) \
  begin \
    fork begin \
      fork \
        begin \
          WAIT_ \
        end \
        begin \
          EXIT_ \
          if (MSG_ != "") begin \
            `dv_info(MSG_, uvm_pkg::UVM_HIGH, ID_) \
          end \
        end \
      join_any \
      disable fork; \
    end join \
  end
`endif

// Wait for one of two statements but stop early if the EXIT statement completes.
//
// Example usage:
//
//    `DV_SPINWAIT_EXIT_MULTI(do_something_time_consuming();,
//                      do_something_else_time_consuming();,
//                      wait(stop_now_flag);,
//                      "The stop flag was set when we were working")
`ifndef DV_SPINWAIT_EXIT_MULTI
`define DV_SPINWAIT_EXIT_MULTI(WAIT_1_, WAIT_2_, EXIT_, MSG_ = "exit condition occurred!", ID_ =`gfn) \
  `DV_SPINWAIT_EXIT(fork begin \
                      fork \
                        begin WAIT_1_ end \
                        begin WAIT_2_ end \
                      join_any \
                      disable fork; \
                    end join, \
                    EXIT_, MSG_, ID_)
`endif

// macro that waits for a given delay and then reports an error
`ifndef DV_WAIT_TIMEOUT
`define DV_WAIT_TIMEOUT(TIMEOUT_NS_, ID_  = `gfn, ERROR_MSG_ = "timeout occurred!", REPORT_FATAL_ = 1) \
  begin \
    #(TIMEOUT_NS_ * 1ns); \
    if (REPORT_FATAL_) begin \
      `dv_fatal(ERROR_MSG_, ID_) \
    end else begin \
      `dv_error(ERROR_MSG_, ID_) \
    end \
  end
`endif

// Wait for a statement, but exit early after a timeout
`ifndef DV_SPINWAIT
`define DV_SPINWAIT(WAIT_, MSG_ = "timeout occurred!", TIMEOUT_NS_ = default_spinwait_timeout_ns, ID_ =`gfn, REPORT_FATAL_ = 1) \
  `DV_SPINWAIT_EXIT(WAIT_, `DV_WAIT_TIMEOUT(TIMEOUT_NS_, ID_, MSG_, REPORT_FATAL_);, "", ID_)
`endif

// a shorthand of `DV_SPINWAIT(wait(...))
`ifndef DV_WAIT
`define DV_WAIT(WAIT_COND_, MSG_ = "wait timeout occurred!", TIMEOUT_NS_ = default_spinwait_timeout_ns, ID_ =`gfn, REPORT_FATAL_ = 1) \
  `DV_SPINWAIT(wait (WAIT_COND_);, MSG_, TIMEOUT_NS_, ID_, REPORT_FATAL_)
`endif

// Wait for one of two statements, but exit early after a timeout
`ifndef DV_WAIT_MULTI
`define DV_WAIT_MULTI(WAIT_COND_1_, WAIT_COND_2_, MSG_ = "wait timeout occurred!", TIMEOUT_NS_ = default_spinwait_timeout_ns, ID_ =`gfn, REPORT_FATAL_ = 1) \
  `DV_SPINWAIT_EXIT_MULTI(WAIT_COND_1_, WAIT_COND_2_, `DV_WAIT_TIMEOUT(TIMEOUT_NS_, ID_, MSG_, REPORT_FATAL_);, "", ID_)
`endif

// Control assertions in the DUT.
//
// This macro is invoked in top level testbench that instantiates the DUT. It spawns off an initial
// block that forever waits for a resource of type bit named by the string arg ~LABEL_~ that
// can be set by any entity in the testbench. Based on the value set, it enables or disables the
// assertions at the hierarchy of the provided path. The entity setting the resource value invokes
// uvm_config_db#(bit)::set(...) and this macro calls the corresponding get.
//
// LABEL_ : Name of the assertion control resource bit (string).
// HIER_  : Path to the module within which the assertion is controlled.
// LEVELS_: Number of levels within the module to control the assertions.
// SCOPE_ : Hierarchical string path to the testbench where this macro is invoked, example: %m.
// ID_    : Identifier string used for UVM logs.
`ifndef DV_ASSERT_CTRL
`define DV_ASSERT_CTRL(LABEL_, HIER_, LEVELS_ = 0, SCOPE_ = "", ID_ = $sformatf("%m")) \
  initial begin \
    bit assert_en; \
    forever begin \
      uvm_config_db#(bit)::wait_modified(null, SCOPE_, LABEL_); \
      if (!uvm_config_db#(bit)::get(null, SCOPE_, LABEL_, assert_en)) begin \
        `uvm_fatal(ID_, $sformatf("Failed to get \"%0s\" from uvm_config_db", LABEL_)) \
      end \
      if (assert_en) begin \
        `uvm_info(ID_, $sformatf("Enabling assertions: %0s", `DV_STRINGIFY(HIER_)), UVM_LOW) \
        $asserton(LEVELS_, HIER_); \
      end else begin \
        `uvm_info(ID_, $sformatf("Disabling assertions: %0s", `DV_STRINGIFY(HIER_)), UVM_LOW) \
        $assertoff(LEVELS_, HIER_); \
        $assertkill(LEVELS_, HIER_); \
      end \
    end \
  end
`endif

// Retrieves a plusarg value representing an enum literal.
//
// The plusarg is parsed as a string, which needs to be converted into the enum literal whose name
// matches the string. This functionality is provided by the UVM helper function below.
//
// ENUM_: The enum type.
// VAR_: The enum variable to which the plusarg value will be set (must be declared already).
// PLUSARG_: the name of the plusarg (as raw text). This is typically the same as the enum variable.
// CHECK_EXISTS_: Throws a fatal error if the plusarg is not set.
`ifndef DV_GET_ENUM_PLUSARG
`define DV_GET_ENUM_PLUSARG(ENUM_, VAR_, PLUSARG_, CHECK_EXISTS_ = 0, ID_ = `gfn) \
  begin \
    string str; \
    if ($value$plusargs(`"``PLUSARG_``=%0s`", str)) begin \
      if (!uvm_enum_wrapper#(ENUM_)::from_name(str, VAR_)) begin \
        `uvm_fatal(ID_, $sformatf(`"Cannot find %s from enum ``ENUM_```", VAR_.name())) \
      end \
    end else if (CHECK_EXISTS_) begin \
      `uvm_fatal(ID_, `"Please pass the plusarg +``PLUSARG_``=<``ENUM_``-literal>`") \
    end \
  end
`endif

// Retrieves a queue of plusarg value from a string.
//
// The plusarg is parsed as a string, which needs to be converted into a queue of string which given delimiter.
// This functionality is provided by the UVM helper function below.
//
// QUEUE_: The queue of string to which the plusarg value will be set (must be declared already).
// PLUSARG_: the name of the plusarg (as raw text). This is typically the same as the enum variable.
// DELIMITER_: the delimiter that separate each item in the plusarg string value.
// CHECK_EXISTS_: Throws a fatal error if the plusarg is not set.
`ifndef DV_GET_QUEUE_PLUSARG
`define DV_GET_QUEUE_PLUSARG(QUEUE_, PLUSARG_, DELIMITER_ = ",", CHECK_EXISTS_ = 0, ID_ = `gfn) \
  begin \
    string str; \
    if ($value$plusargs(`"``PLUSARG_``=%0s`", str)) begin \
      str_split(str, QUEUE_, DELIMITER_); \
    end else if (CHECK_EXISTS_) begin \
      `uvm_fatal(ID_, `"Please pass the plusarg +``PLUSARG_``=<``ENUM_``-literal>`") \
    end \
  end
`endif

// Enable / disable assertions at a module hierarchy identified by LABEL_.
//
// This goes in conjunction with `DV_ASSERT_CTRL() macro above, but is invoked in the entity that is
// sending the req to turn on / off the assertions. Note that piece of code invoking this macro
// does not have the information on the actual hierarchical path to the module or the levels - this
// is 'wrapped' into the LABEL_ instead. DV user needs to uniquify the label sufficiently enough to
// reflect it.
//
// LABEL_ : Name of the assertion control resource bit (string).
// VALUE_ : Value of the control bit - 1 - enable assertions, 0 - disable assertions.
// SCOPE_ : Hierarchical string path to the testbench where this macro is invoked, example: %m.
`ifndef DV_ASSERT_CTRL_REQ
`define DV_ASSERT_CTRL_REQ(LABEL_, VALUE_, SCOPE_="") \
  begin \
    uvm_config_db#(bit)::set(null, SCOPE_, LABEL_, VALUE_); \
  end
`endif

// Macros for logging (info, warning, error and fatal severities).
//
// These are meant to be invoked in modules and interfaces that are shared between DV and Verilator
// testbenches. We waive the lint requirement for these to be in uppercase, since they are
// UVM-adjacent.
`ifdef UVM
`ifndef dv_info
  // verilog_lint: waive macro-name-style
  `define dv_info(MSG_,  VERBOSITY_ = uvm_pkg::UVM_LOW, ID_ = $sformatf("%m")) \
    if (uvm_pkg::uvm_report_enabled(VERBOSITY_, uvm_pkg::UVM_INFO, ID_)) begin \
        uvm_pkg::uvm_report_info(ID_, MSG_, VERBOSITY_, `uvm_file, `uvm_line, "", 1); \
    end
`endif

`ifndef dv_warning
  // verilog_lint: waive macro-name-style
  `define dv_warning(MSG_, ID_ = $sformatf("%m")) \
    if (uvm_pkg::uvm_report_enabled(uvm_pkg::UVM_NONE, uvm_pkg::UVM_WARNING, ID_)) begin \
        uvm_pkg::uvm_report_warning(ID_, MSG_, uvm_pkg::UVM_NONE, `uvm_file, `uvm_line, "", 1); \
    end
`endif

`ifndef dv_error
  // verilog_lint: waive macro-name-style
  `define dv_error(MSG_, ID_ = $sformatf("%m")) \
    if (uvm_pkg::uvm_report_enabled(uvm_pkg::UVM_NONE, uvm_pkg::UVM_ERROR, ID_)) begin \
        uvm_pkg::uvm_report_error(ID_, MSG_, uvm_pkg::UVM_NONE, `uvm_file, `uvm_line, "", 1); \
    end
`endif

`ifndef dv_fatal
  // verilog_lint: waive macro-name-style
  `define dv_fatal(MSG_, ID_ = $sformatf("%m")) \
    if (uvm_pkg::uvm_report_enabled(uvm_pkg::UVM_NONE, uvm_pkg::UVM_FATAL, ID_)) begin \
        uvm_pkg::uvm_report_fatal(ID_, MSG_, uvm_pkg::UVM_NONE, `uvm_file, `uvm_line, "", 1); \
    end
`endif

`else // UVM

`ifndef dv_info
  // verilog_lint: waive macro-name-style
  `define dv_info(MSG_, VERBOSITY = DUMMY_, ID_ = $sformatf("%m")) \
    $display("%0t: (%0s:%0d) [%0s] %0s", $time, `__FILE__, `__LINE__, ID_, MSG_);
`endif

`ifndef dv_warning
  // verilog_lint: waive macro-name-style
  `define dv_warning(MSG_, ID_ = $sformatf("%m")) \
    $warning("%0t: (%0s:%0d) [%0s] %0s", $time, `__FILE__, `__LINE__, ID_, MSG_);
`endif

`ifndef dv_error
  // verilog_lint: waive macro-name-style
  `define dv_error(MSG_, ID_ = $sformatf("%m")) \
    $error("%0t: (%0s:%0d) [%0s] %0s", $time, `__FILE__, `__LINE__, ID_, MSG_);
`endif

`ifndef dv_fatal
  // verilog_lint: waive macro-name-style
  `define dv_fatal(MSG_, ID_ = $sformatf("%m")) \
    $fatal(1, "%0t: (%0s:%0d) [%0s] %0s", $time, `__FILE__, `__LINE__, ID_, MSG_);
`endif

`endif // UVM

// Macros for constrain clk with common frequencies
//
// Nominal clock frequency range is 24Mhz - 100Mhz and use higher weights on 24, 25, 48, 50, 100,
// To mimic manufacturing conditions (when clocks are uncalibrated), we need to be able to go as
// low as 5MHz.
`ifndef DV_COMMON_CLK_CONSTRAINT
`define DV_COMMON_CLK_CONSTRAINT(FREQ_) \
  FREQ_ dist { \
    [5:23]  :/ 2, \
    [24:25] :/ 2, \
    [26:47] :/ 1, \
    [48:50] :/ 2, \
    [51:95] :/ 1, \
    96      :/ 1, \
    [97:99] :/ 1, \
    100     :/ 1  \
  };
`endif

// Enables build-time randomization of fixed design constants.
//
// This is meant to be overridden externally by passing `+define+BUILD_SEED=<value>`.
`ifndef BUILD_SEED
  `define BUILD_SEED 1
`endif

// Max value out of 2 given expressions.
//
// Duplicate of dv_utils_pkg::max2() function, but this is better because
// it can consume different data types directly without the need for casting.
`ifndef DV_MAX2
  `define DV_MAX2(a, b) ((a) > (b) ? (a) : (b))
`endif

// Creates a signal probe function to sample / force / release an internal signal.
//
// If there is a need to sample / force an internal signal, then it must be done in the testbench,
// or in an interface bound to the DUT. This macro creates a standardized signal probe function
// to be defined in an interface. The generated function can then be invoked in test sequences
// or other UVM classes. The macro takes 2 arguments - name of the function and the hierarchical
// path to the signal. If invoked in an interface which is bound to the DUT, the signal can be a
// partial hierarchical path within the DUT. The generated function accepts 2 arguments - the first
// indicates the probe action (sample, force or release) of type dv_utils_pkg::signal_probe_e. The
// second argument is the value to be forced. If sample action is chosen, then it returns the
// sampled value (for other actions as well).
//
// The suggested naming convention for the function is:
//   signal_probe_<DUT_or_IP_block_name>_<signal_name>
//
// This macro must be invoked in an interface or module.
`ifndef DV_CREATE_SIGNAL_PROBE_FUNCTION
`define DV_CREATE_SIGNAL_PROBE_FUNCTION(FUNC_NAME_, SIGNAL_PATH_, SIGNAL_WIDTH_ = uvm_pkg::UVM_HDL_MAX_WIDTH) \
  function static logic [SIGNAL_WIDTH_-1:0] FUNC_NAME_(dv_utils_pkg::signal_probe_e kind,     \
                                                       logic [SIGNAL_WIDTH_-1:0] value = '0); \
    case (kind)                                                                               \
      dv_utils_pkg::SignalProbeSample: ;                                                      \
      dv_utils_pkg::SignalProbeForce: force SIGNAL_PATH_ = value;                             \
      dv_utils_pkg::SignalProbeRelease: release SIGNAL_PATH_;                                 \
      default: `uvm_fatal(`"FUNC_NAME_`", $sformatf("Bad value: %0d", kind))                  \
    endcase                                                                                   \
    return SIGNAL_PATH_;                                                                      \
  endfunction
`endif

// Usage:`OTDBG(( string ))
// This macro has unique keyword 'OTDBG' and timestamp only.
// Use for the temporary print to distinguish from `uvm_info.
// Do not leave this macro in other source files in the remote repo.
`ifndef OTDBG
  `define OTDBG(x) \
  $write($sformatf("%t:OTDBG:%s:%d:",$time,`__FILE__, `__LINE__));\
  $display($sformatf x);
`endif
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
      monitor_reset();
    join_none
  endtask

  task collect_expected();
    ITEM_T item, clone;

    forever begin
      req_fifo.get(item);

      if (cfg.in_reset) begin
        continue;
      end

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

      if (cfg.in_reset) begin
        exp_q.delete();
        continue;
      end

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

  task monitor_reset();
    bit prev_reset;

    prev_reset = cfg.in_reset;
    forever begin
      @(cfg.in_reset);
      if (!prev_reset && cfg.in_reset) begin
        `uvm_info("SCB", "Reset detected, clearing scoreboard", UVM_HIGH)
        exp_q.delete();
      end
      prev_reset = cfg.in_reset;
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
// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_sequencer #(type ITEM_T     = uvm_sequence_item,
                      type CFG_T      = hdv_agent_cfg,
                      type RSP_ITEM_T = ITEM_T)
  extends uvm_sequencer #(.REQ(ITEM_T), .RSP(RSP_ITEM_T));

  `uvm_component_param_utils(hdv_sequencer #(.ITEM_T     (ITEM_T),
                                             .CFG_T      (CFG_T),
                                             .RSP_ITEM_T (RSP_ITEM_T)))

  // These FIFOs collect items when req/rsp is received, which are used to communicate between
  // monitor and sequences. These FIFOs are optional
  // When device is re-active, it gets items from req_analysis_fifo and send rsp to driver
  // When this is a high-level agent, monitors put items to these 2 FIFOs for high-level seq
  uvm_tlm_analysis_fifo #(ITEM_T)     req_analysis_fifo;
  uvm_tlm_analysis_fifo #(RSP_ITEM_T) rsp_analysis_fifo;

  CFG_T cfg;

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Avoid null pointer if the cfg is not defined.
    if (cfg == null) begin
      `uvm_fatal(`gfn, "cfg handle is null.")
    end else begin
      if (cfg.has_req_fifo) req_analysis_fifo = new("req_analysis_fifo", this);
      if (cfg.has_rsp_fifo) rsp_analysis_fifo = new("rsp_analysis_fifo", this);
    end
  endfunction : build_phase

endclass
// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

class hdv_sequence #(type REQ         = uvm_sequence_item,
                          type RSP         = REQ,
                          type CFG_T       = hdv_agent_cfg,
                          type SEQUENCER_T = hdv_sequencer) extends uvm_sequence#(REQ, RSP);
  `uvm_object_param_utils(hdv_sequence #(REQ, RSP, CFG_T, SEQUENCER_T))
  `uvm_declare_p_sequencer(SEQUENCER_T)

  CFG_T cfg;

  `uvm_object_new

  task pre_start();
    super.pre_start();
    cfg = p_sequencer.cfg;
  endtask

  task body();
    `uvm_fatal(`gtn, "Need to override this when you extend from this class!")
  endtask : body

endclass
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
