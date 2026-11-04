`ifndef IIC_MEM_REG_BLOCK_SV
    `define IIC_MEM_REG_BLOCK_SV

        class iic_mem_reg_block extends uvm_reg_block;
            
            `uvm_object_utils(iic_mem_reg_block)

                 bit [6:0]          slave_addr;
            rand iic_mem_addr_reg   addr_reg;
            rand iic_mem_mem        mem_file;
                 uvm_reg_map        mem_file_map;
            
            function new(string name = "");
                super.new(name, UVM_CVR_ALL);
                slave_addr = 7'b101_0001;
            endfunction //new()

            virtual function void build();
                // Create the memory instance
                this.mem_file_map = create_map(
                    .name("mem_file_map"), 
                    .base_addr('h0),
                    .n_bytes(1),
                    .endian(UVM_LITTLE_ENDIAN),
                    .byte_addressing(1)
                    );
                
                // Creates and configures the memory file
                this.mem_file = iic_mem_mem::type_id::create("mem_file");
                this.mem_file.configure(this, "");

                // Creates and configures the address register
                this.addr_reg = iic_mem_addr_reg::type_id::create("addr_reg", , get_full_name());
                this.addr_reg.configure(this, null, "");
                this.addr_reg.build();

                // Adds the memory file to the memory map (Address Register is unmapped)
                this.mem_file_map.add_mem(.mem(mem_file), .offset('h0), .rights("RW"));
                lock_model();

            endfunction

        endclass //iic_mem_reg_block extends uvm_reg_block

`endif