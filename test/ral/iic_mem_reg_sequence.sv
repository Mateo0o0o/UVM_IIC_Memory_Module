`ifndef IIC_MEM_REG_SEQUENCE_SV
    `define IIC_MEM_REG_SEQUENCE_SV

    class iic_mem_reg_sequence extends iic_mem_sequence_base;

        `uvm_object_utils(iic_mem_reg_sequence)

        iic_mem_reg_block reg_block;
        
        uvm_status_e status;

        function new(string name = "");
            super.new(name);
        endfunction //new()

        virtual task body();
            
            repeat(`TEST_NUM) begin
                item = iic_mem_item::type_id::create("item");
                item.set_slave_addr(7'b101_0001);
                assert(item.randomize());

                reg_block.mem_file.write(status, item.mem_addr, item.mem_data, UVM_FRONTDOOR);
                if (status != UVM_IS_OK)
                    `uvm_error("RAL", "Memory write failed")
            end

        endtask

    endclass //iic_mem_reg_sequence extends iic_mem_sequence_base

`endif