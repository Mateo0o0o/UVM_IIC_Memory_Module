`ifndef IIC_MEM_COVERAGE_SV
    `define IIC_MEM_COVERAGE_SV

    class iic_mem_coverage extends uvm_subscriber#(iic_mem_item);
        
        `uvm_component_utils(iic_mem_coverage)
        
        iic_mem_item item;

        covergroup iic_mem_transaction;

            coverpoint item.mem_addr {
                bins low_addr   = {[0               : (2**`AWIDTH/2)-1]};
                bins high_addr  = {[(2**`AWIDTH/2)  : (2**`AWIDTH)  -1]};
                bins all0_addr  = {0};
                bins all1_addr  = {{`AWIDTH{1}}};
            }

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