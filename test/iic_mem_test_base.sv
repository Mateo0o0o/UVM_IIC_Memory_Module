`ifndef IIC_MEM_TEST_BASE_SV
    `define IIC_MEM_TEST_BASE_SV

        class iic_mem_test_base extends uvm_test;
            
            iic_mem_env env;

            `uvm_component_utils(iic_mem_test_base)

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                
                env = iic_mem_env::type_id::create("env", this);
            endfunction

        endclass //iic_mem_test_base extends uvm_test

`endif