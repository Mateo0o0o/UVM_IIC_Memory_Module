`ifndef IIC_MEM_SEQUENCE_SIMPLE_SV
    `define IIC_MEM_SEQUENCE_SIMPLE_SV

        class iic_mem_sequence_simple extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_simple)
            
            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(`TEST_NUM) begin
                    item = iic_mem_item::type_id::create("item");
                    item.set_slave_addr(7'b101_0001);

                    // `uvm_do_with(item, {item.mem_mode == MEM_READ;});
                    `uvm_do(item);
                end
            endtask

        endclass //iic_mem_sequence_simple extends iic_mem_sequence_base

`endif