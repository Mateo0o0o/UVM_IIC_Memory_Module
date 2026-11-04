interface iic_if (input logic clk);
    
    logic   rst_n;
    wire    sda;
    wire    scl;

    logic dut_sda_ena;
    logic dut_sda_out;
    logic uvm_sda_ena;
    logic uvm_sda_out;
    logic uvm_scl_ena;
    logic uvm_scl_out;

    assign sda = dut_sda_ena ? dut_sda_out : (uvm_sda_ena ? uvm_sda_out : 1'b1 );
    assign scl = uvm_scl_ena ? uvm_scl_out : 1;

    // clocking iif_cb @(posedge clk);
    //     default input #1ns output #2ns;
    //     input rst_n;
    //     input uvm_scl_ena, uvm_sda_ena;
    //     output uvm_scl_out, uvm_sda_out;
    // endclocking
        
endinterface //iic_if