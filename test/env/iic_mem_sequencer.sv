`ifndef IIC_MEM_SEQUENCER_SV
    `define IIC_MEM_SEQUENCER_SV

        class iic_mem_sequencer extends uvm_sequencer#(iic_mem_item);
            
            `uvm_component_utils(iic_mem_sequencer)
            
            function new(string name = "", uvm_component parent);
                super.new(name, parent);
            endfunction //new()
            
        endclass //iic_mem_sequencer extends uvm_sequencer

`endif