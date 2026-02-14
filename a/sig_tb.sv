module sig_tb;
  import uvm_pkg::*;
  import hdv_pkg::*;
  import sig_pkg::*;

  bit clk;
  bit reset;

  always #5 clk = ~clk;

  initial begin
    reset = 1;
    #12 reset = 0;
  end

  sig_if intf (
      clk,
      reset
  );

  initial begin
    static sig_agent_cfg agent_cfg = sig_agent_cfg::type_id::create("agent_cfg");
    static hdv_env_cfg env_cfg = hdv_env_cfg::type_id::create("env_cfg");
    
    agent_cfg.vif = intf;
    
    uvm_config_db#(sig_agent_cfg)::set(uvm_root::get(), "*", "cfg", agent_cfg);
    uvm_config_db#(hdv_env_cfg)::set(uvm_root::get(), "*", "cfg", env_cfg);
  end

  initial begin
    run_test();
  end

endmodule
