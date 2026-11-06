`ifndef IIC_MEM_TEST_ALL_RANDOM_SEQ_SV
    `define IIC_MEM_TEST_ALL_RANDOM_SEQ_SV

        class iic_mem_test_all_random_seq extends iic_mem_test_base;

            `uvm_component_utils(iic_mem_test_all_random_seq)

            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()

            virtual task run_phase(uvm_phase phase);
                int which_test;
                
                phase.raise_objection(this, "TEST DONE");
                    `uvm_info("TEST STATUS", "This is the Start of the Test", UVM_LOW)
                    repeat (`TEST_NUM) begin
                        which_test = $urandom_range(3);
                        case (which_test)
                            0 : begin
                                    iic_mem_sequence_wr seq;
                                    seq = iic_mem_sequence_wr::type_id::create("seq");
                                    seq.start(env.agent.sequencer);
                                end
                            1 : begin
                                    iic_mem_sequence_overwrite seq;
                                    seq = iic_mem_sequence_overwrite::type_id::create("seq");
                                    seq.start(env.agent.sequencer);
                                end
                            2 : begin
                                    iic_mem_sequence_slave seq;
                                    seq = iic_mem_sequence_slave::type_id::create("seq");
                                    seq.start(env.agent.sequencer);
                                end
                            3 : begin
                                    iic_mem_sequence_random seq;
                                    seq = iic_mem_sequence_random::type_id::create("seq");
                                    seq.start(env.agent.sequencer);
                                end
                        endcase
                    end
                    `uvm_info("TEST STATUS", "This is the End of the Test", UVM_LOW)
                phase.drop_objection(this, "TEST DONE");

            endtask

        endclass //iic_mem_test_reg_access extends iic_mem_test_base

`endif