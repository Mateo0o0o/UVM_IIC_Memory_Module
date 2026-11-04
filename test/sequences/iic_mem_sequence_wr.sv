`ifndef IIC_MEM_SEQUENCE_WR_SV
    `define IIC_MEM_SEQUENCE_WR_SV

        class iic_mem_sequence_wr extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_wr)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(`TEST_NUM) begin
                    item = iic_mem_item::type_id::create("item");
                    item.set_slave_addr(slave_addr);

                    // Writes to a random memory address
                    `uvm_do_with(item, {item.mem_mode == MEM_WRITE;});
                    
                    // Saves the current memory address
                    this.mem_addr = item.mem_addr; 
                    
                    // Reads the value of the saved memory address
                    `uvm_do_with(item, {
                        item.mem_addr == local::mem_addr;
                        item.mem_mode == MEM_READ;
                    });

                end
            endtask

        endclass //iic_mem_sequence_wr extends iic_mem_sequence_base

`endif