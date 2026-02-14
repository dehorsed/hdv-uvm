class sig_sequence extends hdv_sequence #(sig_seq_item, sig_seq_item, hdv_agent_cfg, sig_sequencer);
  `uvm_object_utils(sig_sequence)

  `uvm_object_new

  virtual task body();
    for (int i = 0; i < 1000; i++) begin
      req = sig_seq_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize());
      send_request(req);
      wait_for_item_done();
    end
  endtask

endclass
