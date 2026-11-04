`ifndef IIC_MEM_MEM_SV
    `define IIC_MEM_MEM_SV

    class iic_mem_mem extends uvm_mem;
        
        `uvm_object_utils(iic_mem_mem)
        
        function new(string name = "");
            super.new(
                .name(name),
                .size(256),
                .n_bits(8),
                .access("RW"),
                .has_coverage("UVM_NO_COVERAGE")
            );
        endfunction //new()
        
    endclass //iic_mem_mem extends uvm_mem

`endif