class sig_test extends hdv_test#(hdv_env_cfg, sig_env, sig_sequence);
  `uvm_component_utils(sig_test)

  function new(string name = "sig_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass
