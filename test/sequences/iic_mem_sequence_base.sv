`ifndef IIC_MEM_SEQUENCE_BASE_SV 
    `define IIC_MEM_SEQUENCE_BASE_SV

        class iic_mem_sequence_base extends uvm_sequence#(iic_mem_item);
            
            iic_mem_item    item;
            mem_addr_t      mem_addr;
            slave_addr_t    orig_slave_addr = 7'b101_0001;
            slave_addr_t    slave_addr;
            int unsigned    iterations = 1;

            `uvm_object_utils(iic_mem_sequence_base)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual function void set_iterations(int unsigned iter);
                iterations = iter;
            endfunction
            
        endclass //iic_mem_sequence_base extends uvm_sequence

`endif