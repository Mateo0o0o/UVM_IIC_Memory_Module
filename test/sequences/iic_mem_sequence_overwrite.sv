`ifndef IIC_MEM_SEQUENCE_OVERWRITE_SV
    `define IIC_MEM_SEQUENCE_OVERWRITE_SV

        class iic_mem_sequence_overwrite extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_overwrite)
            local int unsigned number_of_overwrites;

            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                
                repeat (`TEST_NUM) begin
                    item = iic_mem_item::type_id::create("item");
                    item.set_slave_addr(slave_addr);

                    // Writes to a random memory address
                    `uvm_do_with(
                        item,
                        {item.mem_mode == MEM_WRITE;}
                    )
                    // Saves the current memory address
                    this.mem_addr = item.mem_addr;

                    // Overwrites the saved memory address
                    number_of_overwrites = $urandom_range(5);
                    repeat (number_of_overwrites) begin
                        `uvm_do_with(
                            item,
                            {item.mem_mode == MEM_WRITE;
                            item.mem_addr == local::mem_addr;}
                        )
                    end

                    // Reads the updated content of the memory address
                    `uvm_do_with(
                        item,
                        {item.mem_mode == MEM_READ;
                        item.mem_addr == local::mem_addr;}
                    )
                end

            endtask

        endclass //iic_mem_sequence_overwrite extends iic_mem_sequence_base

`endif