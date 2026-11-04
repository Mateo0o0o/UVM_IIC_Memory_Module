`ifndef IIC_MEM_MONITOR_SV
    `define IIC_MEM_MONITOR_SV

    class iic_mem_monitor extends uvm_monitor;
        
        `uvm_component_utils(iic_mem_monitor)
        
        bit repeated_start;
        iic_vif_t vif;
        uvm_analysis_port#(iic_mem_item) analysis_port; 

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction //new()

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            analysis_port = new("analysis_port", this);

            if(!uvm_config_db#(iic_vif_t)::get(this, "", "vif", vif)) begin
                `uvm_error(get_type_name(), "Could no get the virtual interface from the database")
            end
        endfunction

        virtual task run_phase(uvm_phase phase);
            iic_mem_item item;
            iic_mem_item write_item_temp;
            iic_mem_item read_item_temp;
                    
            forever begin
                bit write_done;
                bit write_success;
                bit read_done;
                bit read_success;

                repeated_start = 0;

                item            = iic_mem_item::type_id::create("item");
                write_item_temp = iic_mem_item::type_id::create("write_item_temp");
                read_item_temp  = iic_mem_item::type_id::create("read_item_temp");
                
                fork : TRANSCATION_FORK
                    begin
                        @(posedge vif.sda iff (vif.scl === 1));
                        `uvm_info("STOP", "STOP CONDITION", UVM_HIGH)
                    end

                    begin
                        @(negedge vif.sda iff (vif.scl === 1));
                        `uvm_info("START", "START CONDITION", UVM_HIGH)
                        
                        // Concurrently detects if the current transaction is read or write
                        fork : READ_WRITE_FORK
                            sample_write_transaction(vif, write_item_temp, write_done, write_success);
                            sample_read_transaction(vif, read_item_temp, read_done, read_success);
                        join_none

                        wait(repeated_start || write_done);
                        if (repeated_start) begin
                            wait (read_done);
                        end
                        
                        item = read_success ? read_item_temp : ( write_success ? write_item_temp : item);
                        // `uvm_info("SUCCESS STATUS", $sformatf("read_suc= %0b, write_suc=%0b", read_success, write_success), UVM_NONE)
                        item.status = (read_success ^ write_success) ? UVM_IS_OK : UVM_NOT_OK;
                        `uvm_info("SAMPLE", $sformatf("Sampled slave_addr=%0h, status=%s, mode=%s, mem_addr=%0h, mem_data=%0h", 
                                    item.slave_addr, item.status.name(), item.mem_mode.name(), item.mem_addr, item.mem_data), UVM_HIGH)
                        disable READ_WRITE_FORK;
                    end
                join
                analysis_port.write(item);
                disable TRANSCATION_FORK;
            end
        endtask

    virtual task sample_write_transaction(ref iic_vif_t vif, ref iic_mem_item item, output write_done, output write_success);
        bit slave_mem_addr_ack;
        bit slave_mem_data_ack;
        sample_address_setup(vif, item, slave_mem_addr_ack);
        if (slave_mem_addr_ack) begin
            sample_addr_data(vif, item, 0);
            sample_ack(vif, slave_mem_data_ack);
        end
        write_done = !repeated_start;
        write_success = write_done & slave_mem_addr_ack & slave_mem_data_ack;
    endtask

    virtual task sample_read_transaction(ref iic_vif_t vif, ref iic_mem_item item, 
                                         output read_done, output read_success);
        bit slave_addr_with_read_mode_ack;
        bit slave_mem_addr_ack;
        bit master_nack;
        sample_address_setup(vif, item, slave_mem_addr_ack);
        if (slave_mem_addr_ack) begin
            @(negedge vif.sda);
            if (vif.scl == 1) begin
                repeated_start = 1;
                sample_slave_addr(vif, item);
                sample_mode(vif, item);
                sample_ack(vif, slave_addr_with_read_mode_ack);
                if (slave_addr_with_read_mode_ack) begin
                    // Samples the data being read by the master from the slave
                    sample_addr_data(vif, item, 0);
                    sample_ack(vif, master_nack);
                end
                read_done    = 1;
            end
        end
        read_success = slave_addr_with_read_mode_ack & slave_mem_addr_ack;
    endtask

    // Samples the slave and the address_register
    virtual task sample_address_setup(ref iic_vif_t vif, ref iic_mem_item item, output bit slave_mem_addr_ack);
        bit slave_addr_with_write_mode_ack;
        
        // Samples which slave
        sample_slave_addr(vif, item);
        sample_mode(vif, item);
        sample_ack(vif, slave_addr_with_write_mode_ack);

        // Samples which address is being written in the address register 
        if (slave_addr_with_write_mode_ack) begin
            sample_addr_data(vif, item, 1);
            sample_ack(vif, slave_mem_addr_ack);
        end 
    endtask


    virtual task sample_slave_addr(ref iic_vif_t vif, ref iic_mem_item item);
        for (int i = 6; i > -1; i-- ) begin
            @(posedge vif.scl);
            item.slave_addr[i] = vif.sda;
        end
    endtask
    
    virtual task sample_addr_data(ref iic_vif_t vif, ref iic_mem_item item, input bit is_mem_addr = 1);
        for (int i = 7; i > -1; i-- ) begin
            @(posedge vif.scl);
            if (is_mem_addr) item.mem_addr[i] = vif.sda;
            else             item.mem_data[i] = vif.sda;
        end
    endtask

    virtual task sample_mode(ref iic_vif_t vif, ref iic_mem_item item);
        @(posedge vif.scl);
        item.mem_mode = mem_mode_t'(vif.sda);
    endtask

    virtual task sample_ack(ref iic_vif_t vif, output bit ack);
        @(posedge vif.scl);
        ack = !vif.sda;
    endtask

    endclass //iic_mem_monitor extends uvm_monitor#(iic_mem_item)

`endif