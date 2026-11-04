`ifndef IIC_MEM_SEQUENCE_BASE_SV 
    `define IIC_MEM_SEQUENCE_BASE_SV

        class iic_mem_sequence_base extends uvm_sequence#(iic_mem_item);
            
            iic_mem_item item;

            `uvm_object_utils(iic_mem_sequence_base)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            
        endclass //iic_mem_sequence_base extends uvm_sequence

`endif