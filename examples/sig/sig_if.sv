interface sig_if (
    input logic clk,
    rst_n
);
  logic sig;

  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output sig;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input sig;
  endclocking

  modport DRIVER(clocking driver_cb, input clk, rst_n);
  modport MONITOR(clocking monitor_cb, input clk, rst_n);

endinterface
