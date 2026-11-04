`ifndef IIC_MEM_ENV_SV
    `define IIC_MEM_ENV_SV

        class iic_mem_env extends uvm_env;
            
            `uvm_component_utils(iic_mem_env)
            
            iic_mem_agent           agent;
            iic_mem_scoreboard      scoreboard;

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                
                agent       = iic_mem_agent::type_id::create("agent", this);
                scoreboard  = iic_mem_scoreboard::type_id::create("scoreboard", this);
            endfunction

            virtual function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                agent.monitor.analysis_port.connect(scoreboard.analysis_imp);
            endfunction

        endclass //iic_mem_env extends uvm_env

`endif