`ifndef IIC_MEM_SEQUENCE_BASE_SV 
    `define IIC_MEM_SEQUENCE_BASE_SV

        class iic_mem_sequence_base extends uvm_sequence#(iic_mem_item);
            
            iic_mem_item    item;
            mem_addr_t      mem_addr;
            slave_addr_t    orig_slave_addr = 7'b101_0001;
            slave_addr_t    slave_addr;

            `uvm_object_utils(iic_mem_sequence_base)
            
            function new(string name = "");
                super.new(name);
                slave_addr = orig_slave_addr;
            endfunction //new()

            
        endclass //iic_mem_sequence_base extends uvm_sequence

`endif