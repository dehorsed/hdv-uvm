class sig_env extends hdv_env#(hdv_env_cfg, sig_scoreboard, hdv_env_cov);
  sig_agent sig_agnt_d, sig_agnt_m;

  `uvm_component_utils(sig_env)

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sig_agnt_d = sig_agent::type_id::create("sig_agnt_d", this);
    sig_agnt_m = sig_agent::type_id::create("sig_agnt_m", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    sig_agnt_d.monitor.analysis_port.connect(scoreboard.req_fifo.analysis_export);
    sig_agnt_m.monitor.analysis_port.connect(scoreboard.rsp_fifo.analysis_export);
  endfunction : connect_phase
endclass
