`ifndef IIC_MEM_ITEM_SV
    `define IIC_MEM_ITEM_SV

        class iic_mem_item extends uvm_sequence_item;
            
            `uvm_object_utils(iic_mem_item)
                    
                 bit            rst_n;
            rand mem_data_t     mem_data;
            rand mem_addr_t     mem_addr;
            rand mem_mode_t     mem_mode;
                 slave_addr_t   slave_addr;

            uvm_status_e        status = UVM_NOT_OK;

            function new(string name = "");
                super.new(name);
            endfunction //new()
            
            virtual function void set_slave_addr(slave_addr_t slave_addr);
                this.slave_addr = slave_addr;
            endfunction

        endclass //iic_mem_item extends uvm_sequence_item

`endif