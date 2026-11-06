`ifndef IIC_MEM_TEST_OVERWRITE_SV
    `define IIC_MEM_TEST_OVERWRITE_SV

        class iic_mem_test_overwrite extends iic_mem_test_base;

            `uvm_component_utils(iic_mem_test_overwrite)

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual task run_phase(uvm_phase phase);
                
                phase.raise_objection(this, "TEST DONE");
                `uvm_info("TEST STATUS", "This is the Start of the Test", UVM_LOW)

                `uvm_info("TEST STATUS", "Starting Overwrite Sequence", UVM_LOW)
                
                begin
                    iic_mem_sequence_overwrite seq;
                    seq = iic_mem_sequence_overwrite::type_id::create("seq");
                    seq.set_iterations(`TEST_NUM);
                    seq.start(env.agent.sequencer);
                end

                `uvm_info("TEST STATUS", "This is the End of the Test", UVM_LOW)
                phase.drop_objection(this, "TEST DONE");

            endtask

        endclass //iic_mem_test_reg_access extends iic_mem_test_base

`endif