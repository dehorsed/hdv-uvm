class sig_driver extends hdv_driver#(sig_seq_item, sig_agent_cfg);
  `uvm_component_utils(sig_driver)

  `uvm_component_new

  virtual task drive_trans(ITEM_T req);
    cfg.vif.driver_cb.sig <= 1;
    for (int i = 0; i < req.sig_length; i++) @(posedge cfg.vif.clk);
    cfg.vif.driver_cb.sig <= 0;
    @(posedge cfg.vif.clk);
  endtask

endclass
