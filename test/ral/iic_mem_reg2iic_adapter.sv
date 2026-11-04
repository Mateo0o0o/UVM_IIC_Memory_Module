`ifndef IIC_MEM_REG2IIC_ADAPTER_SV
    `define IIC_MEM_REG2IIC_ADAPTER_SV

    class iic_mem_reg2iic_adapter extends uvm_reg_adapter;
        
        `uvm_object_utils(iic_mem_reg2iic_adapter)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
            iic_mem_item item = iic_mem_item::type_id::create("item");
            item.mem_mode   = mem_mode_t'(rw.kind == UVM_READ);
            item.mem_addr   = rw.addr;
            item.mem_data   = rw.data;
            item.status     = rw.status;
            return item;
        endfunction

        virtual function void bus2reg(uvm_sequence_item uvm_item, ref uvm_reg_bus_op rw);
            iic_mem_item bus_item;
            
            if( !$cast(bus_item, uvm_item) ) begin
                `uvm_fatal(get_type_name(), "Casting iic_mem_item to uvm_sequence_item FAILED")
            end

            rw.kind     = bus_item.mem_mode == MEM_WRITE ? UVM_WRITE : UVM_READ;
            rw.addr     = bus_item.mem_addr;
            rw.data     = bus_item.mem_data;
            rw.status   = bus_item.status; 

        endfunction

    endclass //iic_mem_adapter extends uvm_reg_adapter

`endif