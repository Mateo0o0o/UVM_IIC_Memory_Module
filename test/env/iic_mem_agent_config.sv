`ifndef IIC_MEM_AGENT_CONFIG_SV
    `define IIC_MEM_AGENT_CONFIG_SV

        class iic_mem_agent_config extends uvm_component;
            
            `uvm_component_utils(iic_mem_agent_config)
            
            local iic_vif_t vif;

            function new(string name="", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual function iic_vif_t get_vif();
                `uvm_info(get_type_name(), "Getting VIF", UVM_NONE)
                return vif;
            endfunction

            virtual function void set_vif(iic_vif_t value);
                if (vif == null) begin
                    vif = value;
                end
                else begin
                `uvm_fatal(get_type_name(), "Trying to set the Virtual Interface more than once") 
                end        
            endfunction

            virtual function void start_of_simulation_phase(uvm_phase phase);
                super.start_of_simulation_phase(phase);

                if (get_vif() == null) begin
                    `uvm_fatal(get_type_name(), "The virtual interface is not set")
                end
                else begin
                    `uvm_info("IIC_MEM_CONFIG", "The virtual interface is configured successfully at Start of Simulation Phase", UVM_NONE)
                end
                
            endfunction

        endclass //iic_mem_agent_config extends uvm_component

`endif