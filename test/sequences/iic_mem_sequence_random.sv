`ifndef IIC_MEM_SEQUENCE_RANDOM_SV
    `define IIC_MEM_SEQUENCE_RANDOM_SV

        class iic_mem_sequence_random extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_random)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(`TEST_NUM) begin
                    item = iic_mem_item::type_id::create("item");
                    item.set_slave_addr(slave_addr);

                    // Do random read/write on a random memory address
                    `uvm_do(item);
                end
            endtask

        endclass //iic_mem_sequence_random extends iic_mem_sequence_base

`endif