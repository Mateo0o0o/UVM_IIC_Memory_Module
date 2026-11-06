`ifndef IIC_MEM_SEQUENCE_RANDOM_SV
    `define IIC_MEM_SEQUENCE_RANDOM_SV

        class iic_mem_sequence_random extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_random)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(iterations) begin
                    item = iic_mem_item::type_id::create("item");

                    // Do random read/write on a random memory address
                    start_item(item);
                        void'(item.randomize());
                        item.set_slave_addr(orig_slave_addr);
                    finish_item(item);                
                end
            endtask

        endclass //iic_mem_sequence_random extends iic_mem_sequence_base

`endif