`ifndef IIC_MEM_DRIVER_SV
    `define IIC_MEM_DRIVER_SV

        class iic_mem_driver extends uvm_driver#(iic_mem_item);

            `uvm_component_utils(iic_mem_driver)

            iic_mem_agent_config agent_config;

            local bit disable_scl_forever_loop;

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual task run_phase(uvm_phase phase);
        
                drive_iic();

            endtask

            virtual task drive_iic();
                
                iic_vif_t vif = agent_config.get_vif();

                // Initialize signals
                // vif.scl <= 1;
                // vif.sda <= 1;
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);

                forever begin
                    iic_mem_item item;
                    byte data_read;
                    seq_item_port.get_next_item(item);
                    if (item.mem_mode == MEM_WRITE) begin
                        `uvm_info("WRITING SLAVE", $sformatf("Slave Addr=%0b, Mem_Addr=%0b WData=%0b", 
                                   item.slave_addr, item.mem_addr, item.mem_data), UVM_NONE)
                        drive_slave(vif, item.slave_addr, bit'(MEM_WRITE), item.mem_addr, item.mem_data, data_read);
                    end
                    else begin
                        `uvm_info("READING SLAVE", $sformatf("Slave Addr=%0b, Mem_Addr=%0b RData=%0b",
                                  item.slave_addr, item.mem_addr, data_read), UVM_NONE)
                        drive_slave(vif, item.slave_addr, bit'(MEM_READ), item.mem_addr, item.mem_data, data_read);
                    end
                    seq_item_port.item_done(item);
                end

            endtask

            virtual task drive_slave(iic_vif_t vif, bit[6:0] slave_addr, bit is_read, byte mem_addr, byte mem_data = 0, output byte data_read);
                bit slave_addr_ack;
                bit mem_addr_ack;
                bit mem_data_ack;
                byte mem_data_read;

                fork
                    begin : SCL_GENERATION
                        vif.uvm_scl_ena = 1;
                        write_to_scl(vif, 1);
                        forever @(vif.clk) if(!disable_scl_forever_loop) write_to_scl(vif, vif.clk);
                    end

                    begin
                        // Initiate the transaction with the slave
                        choose_slave(vif, slave_addr, bit'(MEM_WRITE), slave_addr_ack);
                        if (slave_addr_ack) begin
                            // Write memory_address to the address register of the iic_mem 
                            write_to_slave(vif, slave_addr, mem_addr, mem_addr_ack);

                            // Check if slave acknowledges the memory address written to the address_register
                            if(mem_addr_ack) begin

                                // Writes the given data to the specified memory address in the address register
                                if (!is_read) begin
                                    write_to_slave(vif, slave_addr, mem_data,  mem_data_ack);                            
                                end

                                // Initiates another transcation to read the data contained in the specified memory address
                                // in the address register
                                else begin
                                    repeated_start(vif);
                                    choose_slave(vif, slave_addr, bit'(MEM_READ), slave_addr_ack);
                                    if (slave_addr_ack) read_from_slave(vif, mem_data_read);
                                end
                            end

                        end
                        else begin
                            `uvm_info("NO SLAVE", "Slave does not acknowledge the transaction!", UVM_NONE)
                        end

                        stop_condition(vif);
                    end
                join_any
                disable fork;
                data_read = mem_data_read;
            endtask

            virtual task choose_slave(iic_vif_t vif, bit[6:0] slave_addr, bit is_read, output bit ack);
                bit slave_addr_ack;

                // Start condition
                wait (vif.scl == 1);
                #(`CLK_PERIOD / 4)  write_to_sda(vif, 0);

                // Sending the Slave Address
                for (int i = 6; i > -1; i--) begin
                    @(negedge vif.clk);
                    write_to_sda(vif, slave_addr[i]);
                end 

                // Sending Read/Write Bit
                @(negedge vif.clk);
                write_to_sda(vif, is_read);
                @(negedge vif.clk);
                vif.uvm_sda_ena = 0;

                // Acknowledgement from Slave
                @(posedge vif.clk);
                slave_addr_ack = !read_from_sda(vif);
                ack = slave_addr_ack;

            endtask

            virtual task write_to_slave(iic_vif_t vif, bit[6:0] slave_addr, byte data, output bit write_ack);
                
                bit slave_data_ack;

                // Writing the data to slave
                for (int i = 7; i > -1; i--) begin
                    @(negedge vif.clk);
                    write_to_sda(vif, data[i]);
                end
                // Acknowledgement from Slave
                @(negedge vif.clk);
                vif.uvm_sda_ena = 0;
                @(posedge vif.clk);
                slave_data_ack = !read_from_sda(vif);

                // Checks if the slave acknowledges the data
                if (!slave_data_ack) begin
                    `uvm_info("WRITE: DATA NACK", 
                            $sformatf("Slave with slave_addr=%0h did not acknowledge the data: %0h", 
                            slave_addr, data), UVM_NONE)
                end

                write_ack = slave_data_ack;

            endtask

            virtual task read_from_slave(iic_vif_t vif, output byte data_read);
                vif.uvm_sda_ena = 0;
                for (int i = 7; i > -1; i--) begin
                    @(posedge vif.scl);
                    data_read[i] = read_from_sda(vif);
                end

                @(negedge vif.scl);
                write_to_sda(vif, 1); // NACK from the master to tell the slave that the next is stop condition
            endtask

            virtual task write_to_sda(iic_vif_t vif, bit value);
                vif.uvm_sda_ena = 1;
                vif.uvm_sda_out = value;
            endtask

            virtual function void write_to_scl(iic_vif_t vif, bit value);
                // vif.uvm_scl_ena = 1;
                vif.uvm_scl_out = value;
            endfunction

            virtual function bit read_from_sda(iic_vif_t vif);
                vif.uvm_sda_ena = 0;
                return vif.sda;
            endfunction

            virtual task repeated_start(iic_vif_t vif);
                
                @(negedge vif.clk);
                write_to_sda(vif, 1);
                disable_scl_forever_loop = 1;
                write_to_scl(vif, 0);
                @(posedge vif.clk);
                write_to_scl(vif, 1);
                @(negedge vif.clk);
                #(`CLK_PERIOD / 4) write_to_sda(vif, 0);
                @(posedge vif.clk);
                write_to_scl(vif, 0);
                disable_scl_forever_loop = 0;

            endtask

            virtual task stop_condition(iic_vif_t vif) ;

                @(negedge vif.clk);
                write_to_sda(vif, 0);
                @(posedge vif.clk);
                vif.uvm_scl_ena = 0;
                #(`CLK_PERIOD / 4) write_to_sda(vif, 1);                
                @(posedge vif.clk);

            endtask

        endclass //iic_mem_driver extends uvm_driver#()

`endif