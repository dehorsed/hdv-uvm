class sig_driver extends hdv_driver#(sig_seq_item, sig_agent_cfg);
  `uvm_component_utils(sig_driver)

  `uvm_component_new

  virtual task reset_signals();
    @(posedge cfg.vif.reset) cfg.vif.driver_cb.sig <= 0;
  endtask

  virtual task drive_trans(ITEM_T req);
    // Wait until reset is inactive before driving
    wait(!cfg.vif.reset);
    
    cfg.vif.driver_cb.sig <= 1;
    for (int i = 0; i < req.sig_length; i++) @(posedge cfg.vif.clk);
    cfg.vif.driver_cb.sig <= 0;
    @(posedge cfg.vif.clk);
  endtask

endclass
