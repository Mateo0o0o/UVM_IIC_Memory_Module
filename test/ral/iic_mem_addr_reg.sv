`ifndef IIC_MEM_ADDR_REG_SV
    `define IIC_MEM_ADDR_REG_SV

    class iic_mem_addr_reg extends uvm_reg;
        
        `uvm_object_utils(iic_mem_addr_reg)

        rand uvm_reg_field addr_reg;
        
        function new(string name = "");
            super.new(name, 8, UVM_NO_COVERAGE);
        endfunction //new()

        virtual function void build();
            // Create object instance of addr_reg
            addr_reg = uvm_reg_field::type_id::create("addr_reg");
            
            // Configure addr_reg
            addr_reg.configure(
                .parent(this),
                .size(8),
                .lsb_pos(0),
                .access("WO"),
                .volatile(0),
                .reset(8'h0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );
        endfunction
    endclass //iic_mem_addr_reg extends uvm_reg

`endif