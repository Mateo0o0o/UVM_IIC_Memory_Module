package iic_mem_types_pkg;
    
    // Virtual Interface
    typedef virtual iic_if iic_vif_t;

    // Memory Address
    typedef logic [`AWIDTH-1:0] mem_addr_t;

    // Slave Address
    typedef logic [        6:0] slave_addr_t;
    
    // Data
    typedef logic [`DWIDTH-1:0] mem_data_t;

    // Memory Mode
    typedef enum logic {
        MEM_WRITE=0,
        MEM_READ=1
    } mem_mode_t;

    typedef enum logic [3:0] { 
        IDLE = 0,
        START = 1,
        SLAVE_ADDR = 2,
        RW_BIT = 3,
        SLAVE_ACK = 4,
        SEND_DATA = 5,
        GET_DATA = 6,
        DATA_ACK = 7
    } iic_state_t;

endpackage