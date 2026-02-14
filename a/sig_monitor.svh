class sig_monitor extends hdv_monitor #(sig_seq_item, sig_seq_item, sig_seq_item, sig_agent_cfg);
  sig_seq_item trans_collected;

  `uvm_component_utils(sig_monitor)
  `uvm_component_new

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge cfg.vif.clk);
      
      // If reset is active, abort any ongoing transaction
      if (cfg.vif.reset) begin
        if (trans_collected != null) begin
          // Don't write partial transaction on reset
          trans_collected = null;
          phase.drop_objection(this);
        end
      end 
      // Reset is inactive, monitor normal operation
      else begin
        if (cfg.vif.monitor_cb.sig) begin
          if (trans_collected == null) begin
            phase.raise_objection(this);
            trans_collected = new();
            trans_collected.sig_length = 0;
          end
          trans_collected.sig_length++;
        end else begin
          if (trans_collected != null) begin
            `uvm_warning("mon", "write!!")
            analysis_port.write(trans_collected);
            trans_collected = null;
            phase.drop_objection(this);
          end
        end
      end
    end
  endtask
endclass
