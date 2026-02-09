class sig_scoreboard extends hdv_scoreboard#(sig_seq_item);
  `uvm_component_utils(sig_scoreboard)

  `uvm_component_new

  virtual function void check_phase(uvm_phase phase);
    sig_seq_item sent, received;
    if (req_fifo.size != rsp_fifo.size)
      `uvm_error(get_type_name(), "Received is not equal sent!")
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

endclass
