`ifndef IIC_MEM_SEQUENCE_WR_SV
    `define IIC_MEM_SEQUENCE_WR_SV

        class iic_mem_sequence_wr extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_wr)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(iterations) begin
                    item = iic_mem_item::type_id::create("item");

                    // Writes to a random memory address
                    start_item(item);
                        if (item.randomize() with {mem_mode == MEM_WRITE;}) begin end
                        item.set_slave_addr(orig_slave_addr);
                    finish_item(item);
                    
                    // Saves the current memory address
                    this.mem_addr = item.mem_addr; 
                    
                    // Reads the value of the saved memory address of the original slave address
                    start_item(item);
                        if (item.randomize() with {mem_mode == MEM_READ; mem_addr == local::mem_addr;}) begin end
                        item.set_slave_addr(orig_slave_addr);
                    finish_item(item);
                end
            endtask

        endclass //iic_mem_sequence_wr extends iic_mem_sequence_base

`endif