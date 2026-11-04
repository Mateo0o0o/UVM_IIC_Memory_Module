`ifndef IIC_MEM_TEST_PKG_SV
    `define IIC_MEM_TEST_PKG_SV

        package iic_mem_test_pkg;

            import uvm_pkg::*;
            `include "uvm_macros.svh"

            `include "include/iic_mem_param.sv"
            `include "include/iic_mem_typedefs.sv"
            `include "test/env/iic_mem_item.sv"
            `include "test/env/iic_mem_agent_config.sv"
            `include "test/env/iic_mem_sequencer.sv"
            `include "test/env/iic_mem_driver.sv"
            `include "test/env/iic_mem_monitor.sv"
            `include "test/env/iic_mem_coverage.sv"
            `include "test/env/iic_mem_agent.sv"
            `include "test/env/iic_mem_scoreboard.sv"
            `include "test/env/iic_mem_env.sv"

            `include "test/sequences/iic_mem_sequence_base.sv"
            `include "test/sequences/iic_mem_sequence_wr.sv"
            `include "test/sequences/iic_mem_sequence_overwrite.sv"
            `include "test/sequences/iic_mem_sequence_random.sv"

            `include "test/iic_mem_test_base.sv"
            `include "test/iic_mem_test_reg_access.sv"

            `include "test/ral/iic_mem_addr_reg.sv"
            `include "test/ral/iic_mem_mem.sv"
            `include "test/ral/iic_mem_reg_block.sv"
            `include "test/ral/iic_mem_reg2iic_adapter.sv"
            `include "test/ral/iic_mem_reg_env.sv"
            `include "test/ral/iic_mem_my_env.sv"
            `include "test/ral/iic_mem_reg_sequence.sv"
            `include "test/iic_mem_reg_test.sv"

        endpackage

`endif