module iic_mem_tb;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import iic_mem_test_pkg::*;
    
    // Clock Signal
    bit clk;

    // Memory Module Interface
    iic_if iic_mem_if(clk);

    // DUT
    iic_mem dut (
        .rst_n  (iic_mem_if.rst_n),
        .scl    (iic_mem_if.scl),
        .sda_in (iic_mem_if.sda),
        .sda_out(iic_mem_if.dut_sda_out),
        .sda_ena(iic_mem_if.dut_sda_ena)
    );

    // Clock Generator
    always clk = #(`CLK_PERIOD / 2) ~clk;

    initial begin
                        iic_mem_if.rst_n = 1;
        @(negedge clk)  iic_mem_if.rst_n = 0;
        @(negedge clk)  iic_mem_if.rst_n = 1;
    end

    initial begin
        $dumpfile("iic_mem.fst");
        $dumpvars;

        uvm_config_db#(iic_vif_t)::set(null, "uvm_test_top*", "vif", iic_mem_if);

        run_test("");
    end

endmodule