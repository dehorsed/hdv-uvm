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
    // Создаем конфигурационный объект
    static sig_agent_cfg agent_cfg = sig_agent_cfg::type_id::create("agent_cfg");
    static hdv_env_cfg env_cfg = hdv_env_cfg::type_id::create("env_cfg");
    
    // Назначаем интерфейс конфигурационному объекту
    agent_cfg.vif = intf;
    
    // Устанавливаем конфигурационный объект в config_db
    uvm_config_db#(sig_agent_cfg)::set(uvm_root::get(), "*", "cfg", agent_cfg);
    uvm_config_db#(hdv_env_cfg)::set(uvm_root::get(), "*", "cfg", env_cfg);
    
    // Также сохраняем интерфейсы напрямую (опционально, для обратной совместимости)
    uvm_config_db#(virtual sig_if.DRIVER)::set(uvm_root::get(), "*", "vif", intf.DRIVER);
    uvm_config_db#(virtual sig_if.MONITOR)::set(uvm_root::get(), "*", "vif", intf.MONITOR);
  end

  initial begin
    run_test();
  end

endmodule
