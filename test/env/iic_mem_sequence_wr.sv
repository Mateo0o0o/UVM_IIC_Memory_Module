`ifndef IIC_MEM_SEQUENCE_WR_SV
    `define IIC_MEM_SEQUENCE_WR_SV

        class iic_mem_sequence_wr extends iic_mem_sequence_base;
            
            `uvm_object_utils(iic_mem_sequence_wr)
            
            local mem_addr_t mem_addr;

            function new(string name = "");
                super.new(name);
            endfunction //new()

            virtual task body();
                repeat(`TEST_NUM) begin
                    item = iic_mem_item::type_id::create("item");
                    item.set_slave_addr(7'b101_0001);

                    `uvm_do_with(item, {item.mem_mode == MEM_WRITE;});
                    mem_addr = item.mem_addr; 
                    
                    `uvm_do_with(item, {
                        item.mem_addr == local::mem_addr;
                        item.mem_mode == MEM_READ;
                    });

                end
            endtask

        endclass //iic_mem_sequence_wr extends iic_mem_sequence_base

`endif