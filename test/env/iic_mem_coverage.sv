`ifndef IIC_MEM_COVERAGE_SV
    `define IIC_MEM_COVERAGE_SV

    class iic_mem_coverage extends uvm_subscriber#(iic_mem_item);
        
        `uvm_component_utils(iic_mem_coverage)
        
        iic_mem_item item;

        covergroup iic_mem_transaction;

            slave_addr_c : coverpoint item.slave_addr {
                bins hex51      = {7'h51};
                bins not_hex51  = default;
            }
            addr_c : coverpoint item.mem_addr iff (item.status == UVM_IS_OK) {
                bins addr_g0    = {[1                   :   ((2**`AWIDTH)/4)-1]};
                bins addr_g1    = {[  ((2**`AWIDTH)/4)  : 2*((2**`AWIDTH)/4)-1]};
                bins addr_g2    = {[2*((2**`AWIDTH)/4)  : 3*((2**`AWIDTH)/4)-1]};
                bins addr_g3    = {[3*((2**`AWIDTH)/4)  :   ((2**`AWIDTH))-2]};
                bins all0_addr  = {0};
                bins all1_addr  = {{`AWIDTH{1'b1}}};
            }
            data_c : coverpoint item.mem_data iff (item.status == UVM_IS_OK) {
                bins data_g0    = {[1                   :   ((2**`DWIDTH)/4)-1]};
                bins data_g1    = {[  ((2**`DWIDTH)/4)  : 2*((2**`DWIDTH)/4)-1]};
                bins data_g2    = {[2*((2**`DWIDTH)/4)  : 3*((2**`DWIDTH)/4)-1]};
                bins data_g3    = {[3*((2**`DWIDTH)/4)  :   ((2**`DWIDTH))-2]};
                bins all0_data  = {0};
                bins all1_data  = {{`DWIDTH{1'b1}}};
            }
            mode_c : coverpoint item.mem_mode iff (item.status == UVM_IS_OK) {
                bins write      = {MEM_WRITE};
                bins read       = {MEM_READ};
            }

            addr_x_mode : cross addr_c, mode_c;

        endgroup

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
            iic_mem_transaction = new();
        endfunction //new()

        virtual function void write (iic_mem_item transaction);
            item = transaction;
            iic_mem_transaction.sample();
        endfunction

    endclass //iic_mem_coverage extends uvm_subscriber

`endif