`ifndef IIC_MEM_AGENT_SV
    `define IIC_MEM_AGENT_SV

        class iic_mem_agent extends uvm_agent;

            `uvm_component_utils(iic_mem_agent)

            iic_mem_agent_config    agent_config;
            iic_mem_driver          driver;
            iic_mem_monitor         monitor;
            iic_mem_sequencer       sequencer;
            iic_mem_coverage        coverage;

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                agent_config = iic_mem_agent_config::type_id::create("agent_config", this);
                driver       = iic_mem_driver::type_id::create("driver", this);
                sequencer    = iic_mem_sequencer::type_id::create("sequencer", this);
                monitor      = iic_mem_monitor::type_id::create("monitor", this);
                coverage     = iic_mem_coverage::type_id::create("coverage", this);
                
            endfunction

            virtual function void connect_phase(uvm_phase phase);
                iic_vif_t vif;
                
                super.connect_phase(phase);

                if(!uvm_config_db#(iic_vif_t)::get(this, "", "vif", vif)) begin
                    `uvm_fatal("NO VIF", "Could not get the IIC Virtual Interface from the database")
                end
                else begin
                    agent_config.set_vif(vif);
                end

                driver.agent_config = agent_config;
                driver.seq_item_port.connect(sequencer.seq_item_export);
                monitor.analysis_port.connect(coverage.analysis_export);
            endfunction

        endclass //iic_mem_agent extends uvm_agent

`endif