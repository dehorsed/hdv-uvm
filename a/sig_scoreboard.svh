class sig_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sig_scoreboard)

  uvm_tlm_analysis_fifo #(sig_seq_item) req_fifo, rsp_fifo;
  hdv_env_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req_fifo = new("req_fifo", this);
    rsp_fifo = new("rsp_fifo", this);
  endfunction : build_phase

  virtual function void check_phase(uvm_phase phase);
    sig_seq_item sent, received;
    if (req_fifo.size != rsp_fifo.size)
      `uvm_error(get_type_name(), "Received is not equal sent!")
    else if (req_fifo.size() == 0)
      `uvm_error(get_type_name(), "yee")
    else
      while (req_fifo.can_get()) begin
        void'(req_fifo.try_get(sent));
        void'(rsp_fifo.try_get(received));
        assert (sent.sig_length == received.sig_length)
        else `uvm_error(get_type_name(), $sformatf(
                        "Sent length: %h Received length: %h are different.",
                        sent.sig_length,
                        received.sig_length));
        `uvm_info(get_type_name(), $sformatf(
                  "Sent length: %h Received length: %h are the same.",
                  sent.sig_length,
                  received.sig_length),
                  UVM_MEDIUM);
      end
  endfunction : check_phase

endclass : sig_scoreboard
