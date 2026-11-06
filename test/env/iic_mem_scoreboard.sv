`ifndef IIC_MEM_SCOREBOARD_SV
    `define IIC_MEM_SCOREBOARD_SV

    class iic_mem_scoreboard extends uvm_scoreboard;
        
        `uvm_component_utils(iic_mem_scoreboard)

        uvm_analysis_imp#(iic_mem_item, iic_mem_scoreboard) analysis_imp;
        
        function new(string name = "", uvm_component parent);
            super.new(name, parent);
            analysis_imp = new("analysis_imp", this);
        endfunction //new()

        // Reference Model
        mem_data_t  expected_mem [0 : (2**`AWIDTH)-1];          // Memory Array with size of mem_data and addresses of 2^AWIDTH
        bit         written_addr [0 : (2**`AWIDTH)-1]; 

        virtual function void write(iic_mem_item item);
            if (item.slave_addr == 7'b101_0001) begin
                if (item.mem_mode == MEM_WRITE) begin
                    expected_mem[item.mem_addr] = item.mem_data;
                    written_addr[item.mem_addr] = 1;
                    `uvm_info(get_type_name(), $sformatf("Writing data: %0x at addr: %0x", item.mem_data, item.mem_addr), UVM_HIGH);
                end
                else begin
                    if(!written_addr[item.mem_addr]) begin
                        `uvm_info(get_type_name(), $sformatf("addr: %0x read before write, skipping check", item.mem_addr), UVM_LOW);
                    end
                    else if (item.mem_data != expected_mem[item.mem_addr]) begin
                        `uvm_error(get_type_name(), $sformatf("Mismatch at addr %0x : Expected= %0x, Actual= %0x", 
                                                                item.mem_addr, expected_mem[item.mem_addr], item.mem_data))
                    end 
                    else begin
                        `uvm_info(get_type_name(), $sformatf("addr=%0x matched: Data=%0x", item.mem_addr, item.mem_data), UVM_HIGH)
                    end
                end
            end
            else begin
                `uvm_info("NO SLAVE", "No slave responded", UVM_LOW)
            end
            
        endfunction


    endclass //iic_mem_scoreboard extends uvm_scoreboard

`endif