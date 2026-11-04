`ifndef IIC_MEM_REG_TEST_SV
    `define IIC_MEM_REG_TEST_SV

    class iic_mem_reg_test extends uvm_test;

        `uvm_component_utils(iic_mem_reg_test)

        iic_mem_my_env      my_env;
        iic_mem_reg_block   m_reg_block;
        iic_mem_reg_sequence seq;
        
        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction //new()

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            my_env      = iic_mem_my_env::type_id::create("reg_env", this);
            m_reg_block = iic_mem_reg_block::type_id::create("m_reg_block");
            m_reg_block.build();
        endfunction

        virtual task run_phase(uvm_phase phase);

            uvm_status_e status;
            uvm_reg_data_t rdata;
            iic_mem_item item;
            item = iic_mem_item::type_id::create("item");
            phase.raise_objection(this);

            if (!uvm_config_db#(iic_mem_reg_block)::get(this, "", "reg_block", m_reg_block)) begin
                `uvm_fatal("TEST", "Register Model not found in the database")
            end

            begin
                seq             = iic_mem_reg_sequence::type_id::create("seq");
                seq.reg_block   = m_reg_block;
                seq.start(null);
                // seq.start(my_env.agent.sequencer);
            end
            
            phase.drop_objection(this);

        endtask

    endclass //iic_mem_reg_test extends uvm_test

`endif