`ifndef IIC_MEM_MY_ENV_SV
    `define IIC_MEM_MY_ENV_SV

    class iic_mem_my_env extends uvm_env;

        `uvm_component_utils(iic_mem_my_env)

        iic_mem_agent agent;
        iic_mem_reg_env reg_env;

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction //new()

        virtual function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            agent   = iic_mem_agent::type_id::create("agent", this);
            reg_env = iic_mem_reg_env::type_id::create("reg_env", this);
            
            reg_env.agent = agent;
        endfunction

        virtual function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            reg_env.reg_block.mem_file_map.set_sequencer(agent.sequencer, reg_env.adapter); 
        endfunction

    endclass //iic_mem_my_env extends uvm_env

`endif