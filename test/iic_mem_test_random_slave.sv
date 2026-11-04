`ifndef IIC_MEM_TEST_RANDOM_SLAVE_SV
    `define IIC_MEM_TEST_RANDOM_SLAVE_SV

        class iic_mem_test_random_slave extends iic_mem_test_base;

            `uvm_component_utils(iic_mem_test_random_slave)

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual task run_phase(uvm_phase phase);
                
                phase.raise_objection(this, "TEST DONE");
                `uvm_info("TEST STATUS", "This is the Start of the Test", UVM_LOW)

                `uvm_info("TEST STATUS", "Starting Random Slave Address Sequence", UVM_LOW)
                begin
                    iic_mem_sequence_slave seq;
                    seq = iic_mem_sequence_slave::type_id::create("seq");
                    seq.start(env.agent.sequencer);
                end

                `uvm_info("TEST STATUS", "This is the End of the Test", UVM_LOW)
                phase.drop_objection(this, "TEST DONE");

            endtask

        endclass //iic_mem_test_reg_access extends iic_mem_test_base

`endif