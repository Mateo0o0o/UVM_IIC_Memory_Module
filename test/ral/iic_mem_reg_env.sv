`ifndef IIC_MEM_REG_ENV_SV
    `define IIC_MEM_REG_ENV_SV

    class iic_mem_reg_env extends uvm_env;
        
        `uvm_component_utils(iic_mem_reg_env)

        iic_mem_agent                       agent;
        iic_mem_reg_block                   reg_block;
        iic_mem_reg2iic_adapter             adapter;
        uvm_reg_predictor #(iic_mem_item)   predictor;    

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction //new()

        virtual function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            reg_block   = iic_mem_reg_block::type_id::create("reg_block");
            adapter     = iic_mem_reg2iic_adapter::type_id::create("adapter");
            predictor   = uvm_reg_predictor#(iic_mem_item)::type_id::create("predictor", this);

            reg_block.build();
            reg_block.lock_model();
            uvm_config_db#(iic_mem_reg_block)::set(null, "uvm_test_top", "reg_block", reg_block);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            predictor.map       = reg_block.mem_file_map;
            predictor.adapter   = adapter;
            agent.monitor.analysis_port.connect(predictor.bus_in);
        endfunction

    endclass //iic_mem_reg_env extends uvm_env

`endif