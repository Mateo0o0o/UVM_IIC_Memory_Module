`ifndef IIC_MEM_COVERAGE_SV
    `define IIC_MEM_COVERAGE_SV

    class iic_mem_coverage extends uvm_subscriber#(iic_mem_item);
        
        `uvm_component_utils(iic_mem_coverage)
        
        iic_mem_item item;

        covergroup iic_mem_transaction;

            addr_c : coverpoint item.mem_addr {
                bins low_addr   = {[0               : (2**`AWIDTH/2)-1]};
                bins high_addr  = {[(2**`AWIDTH/2)  : (2**`AWIDTH)  -1]};
                bins all0_addr  = {0};
                bins all1_addr  = {{`AWIDTH{1'b1}}};
            }

            data_c : coverpoint item.mem_data {
                bins low_addr   = {[0               : (2**`AWIDTH/2)-1]};
                bins high_addr  = {[(2**`AWIDTH/2)  : (2**`AWIDTH)  -1]};
                bins all0_addr  = {0};
                bins all1_addr  = {{`AWIDTH{1'b1}}};
            }
            mode_c : coverpoint item.mem_mode {
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
            if (item.status == UVM_IS_OK) iic_mem_transaction.sample();
        endfunction

    endclass //iic_mem_coverage extends uvm_subscriber

`endif