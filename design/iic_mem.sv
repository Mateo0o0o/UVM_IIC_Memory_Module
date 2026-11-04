module iic_mem #(
    parameter logic [6:0] SLAVE_ADDR = 7'b101_0001,
    parameter int MEM_DEPTH = 256
)(
    input  logic rst_n,

    // I2C signals
    input  logic scl,
    input  logic sda_in,

    // Open-drain SDA interface for Verilator
    output logic sda_out,
    output logic sda_ena
);

    // ============================================================
    // State machine
    // ============================================================

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_RX_SLAVE_ADDR,
        ST_ACK_SLAVE_ADDR,
        ST_RX_MEM_ADDR,
        ST_ACK_MEM_ADDR,
        ST_RX_WRITE_DATA,
        ST_ACK_WRITE_DATA,
        ST_TX_READ_DATA,
        ST_MASTER_ACK,
        ST_WAIT_STOP
    } state_t;

    state_t state;

    // ============================================================
    // Memory and registers
    // ============================================================

    logic [7:0] memory [0:MEM_DEPTH-1];

    // Assembled incoming byte
    logic [7:0] assembled_byte;

    // Shift register for incoming bytes
    logic [7:0] shift_reg;

    // Data being transmitted to the master
    logic [7:0] read_data;

    // Memory address register
    logic [7:0] mem_addr_reg;

    // Incoming byte bit counter
    logic [3:0] bit_count;

    // Transmitted data bit index: 7 = MSB, 0 = LSB
    logic [2:0] tx_bit_index;

    // Slave address information
    logic rw;
    logic addr_match;

    // ACK sequencing:
    // 0 = waiting for falling edge to assert ACK
    // 1 = ACK asserted, waiting for rising edge
    // 2 = ACK clock completed, waiting for falling edge
    logic [1:0] ack_phase;

    // Master response after slave transmits a byte
    logic master_ack;

    // Previous signal levels for edge detection
    logic prev_scl;
    logic prev_sda;

    integer i;

    // ============================================================
    // Open-drain SDA output
    // ============================================================

    // The slave never drives SDA HIGH.
    assign sda_out = 1'b0;

    // sda_ena = 1: pull SDA LOW
    // sda_ena = 0: release SDA
    //
    // Therefore:
    // Logic 0 -> sda_ena = 1
    // Logic 1 -> sda_ena = 0

    // Incoming byte, including the current SDA bit
    assign assembled_byte = {shift_reg[6:0], sda_in};

    // ============================================================
    // Main I2C protocol logic
    // ============================================================

    // SCL is the protocol clock.
    //
    // Rising SCL edge:
    //   - Sample incoming data
    //   - Sample master's ACK/NACK
    //
    // Falling SCL edge:
    //   - Drive or release SDA
    //   - Set up the next transmitted bit
    //
    // SDA transitions while SCL is HIGH:
    //   - Detect START
    //   - Detect STOP

    always @(scl or sda_in or negedge rst_n) begin

        if (!rst_n) begin

            state          <= ST_IDLE;

            shift_reg      <= 8'h00;
            read_data      <= 8'h00;

            mem_addr_reg   <= 8'h00;

            bit_count      <= 4'd0;
            tx_bit_index   <= 3'd0;

            rw             <= 1'b0;
            addr_match     <= 1'b0;

            ack_phase      <= 2'd0;
            master_ack     <= 1'b0;

            sda_ena        <= 1'b0;

            prev_scl       <= 1'b1;
            prev_sda       <= 1'b1;

            for (i = 0; i < MEM_DEPTH; i = i + 1)
                memory[i] <= 8'h00;

        end else begin

            // ====================================================
            // START AND STOP DETECTION
            // ====================================================

            if ((sda_in != prev_sda) && scl) begin

                // ------------------------------------------------
                // START or REPEATED START
                // ------------------------------------------------

                if (prev_sda && !sda_in) begin

                    // Start receiving a new slave address.
                    //
                    // IMPORTANT:
                    // Do not clear mem_addr_reg here.
                    // It must retain the selected memory address
                    // across a repeated START.

                    state        <= ST_RX_SLAVE_ADDR;

                    shift_reg    <= 8'h00;
                    bit_count    <= 4'd0;

                    rw           <= 1'b0;
                    addr_match   <= 1'b0;

                    ack_phase    <= 2'd0;
                    master_ack   <= 1'b0;

                    sda_ena      <= 1'b0;

                end

                // ------------------------------------------------
                // STOP
                // ------------------------------------------------

                else if (!prev_sda && sda_in) begin

                    state        <= ST_IDLE;

                    bit_count    <= 4'd0;
                    tx_bit_index <= 3'd0;

                    ack_phase    <= 2'd0;

                    sda_ena      <= 1'b0;

                    // Keep mem_addr_reg unchanged.
                    // The next transaction can select another
                    // memory address by sending a new address byte.

                end

            end

            // ====================================================
            // SCL EDGE DETECTION
            // ====================================================

            else if (scl != prev_scl) begin

                // =================================================
                // SCL RISING EDGE
                // =================================================

                if (!prev_scl && scl) begin

                    case (state)

                        // -----------------------------------------
                        // RECEIVE SLAVE ADDRESS + R/W
                        // -----------------------------------------

                        ST_RX_SLAVE_ADDR: begin

                            shift_reg <= assembled_byte;

                            if (bit_count == 4'd7) begin

                                // Address byte:
                                // [7:1] = slave address
                                // [0]   = R/W

                                addr_match <=
                                    (assembled_byte[7:1] == SLAVE_ADDR);

                                rw <= assembled_byte[0];

                                bit_count <= 4'd0;
                                ack_phase <= 2'd0;

                                state <= ST_ACK_SLAVE_ADDR;

                            end else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // SLAVE ADDRESS ACK CLOCK
                        // -----------------------------------------

                        ST_ACK_SLAVE_ADDR: begin

                            if (ack_phase == 2'd1)
                                ack_phase <= 2'd2;

                        end

                        // -----------------------------------------
                        // RECEIVE MEMORY ADDRESS
                        // -----------------------------------------

                        ST_RX_MEM_ADDR: begin

                            shift_reg <= assembled_byte;

                            if (bit_count == 4'd7) begin

                                // Store the received memory address
                                // in the DUT address register.
                                //
                                // The modulo operation keeps the
                                // address within the configured
                                // memory depth.

                                mem_addr_reg <=
                                    assembled_byte % MEM_DEPTH;

                                bit_count <= 4'd0;
                                ack_phase <= 2'd0;

                                state <= ST_ACK_MEM_ADDR;

                            end else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // MEMORY ADDRESS ACK CLOCK
                        // -----------------------------------------

                        ST_ACK_MEM_ADDR: begin

                            if (ack_phase == 2'd1)
                                ack_phase <= 2'd2;

                        end

                        // -----------------------------------------
                        // RECEIVE WRITE DATA
                        // -----------------------------------------

                        ST_RX_WRITE_DATA: begin

                            shift_reg <= assembled_byte;

                            if (bit_count == 4'd7) begin

                                // Write received data into the
                                // selected memory address.

                                memory[mem_addr_reg] <= assembled_byte;

                                // Increment address for possible
                                // sequential write operation.

                                if (mem_addr_reg == MEM_DEPTH - 1)
                                    mem_addr_reg <= 8'd0;
                                else
                                    mem_addr_reg <= mem_addr_reg + 1'b1;

                                bit_count <= 4'd0;
                                ack_phase <= 2'd0;

                                state <= ST_ACK_WRITE_DATA;

                            end else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // WRITE DATA ACK CLOCK
                        // -----------------------------------------

                        ST_ACK_WRITE_DATA: begin

                            if (ack_phase == 2'd1)
                                ack_phase <= 2'd2;

                        end

                        // -----------------------------------------
                        // TRANSMIT READ DATA
                        // -----------------------------------------

                        ST_TX_READ_DATA: begin

                            // The current bit was placed on SDA
                            // during the preceding falling edge.

                            if (tx_bit_index == 3'd0) begin

                                // Bit 0 has now been sampled.
                                // The following falling edge releases
                                // SDA for the master's ACK/NACK.

                                state <= ST_MASTER_ACK;

                            end else begin

                                tx_bit_index <= tx_bit_index - 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // RECEIVE MASTER ACK/NACK
                        // -----------------------------------------

                        ST_MASTER_ACK: begin

                            // Master ACK = SDA LOW
                            // Master NACK = SDA HIGH

                            master_ack <= !sda_in;

                        end

                        default: begin
                        end

                    endcase

                end

                // =================================================
                // SCL FALLING EDGE
                // =================================================

                else begin

                    case (state)

                        // -----------------------------------------
                        // SLAVE ADDRESS ACK/NACK
                        // -----------------------------------------

                        ST_ACK_SLAVE_ADDR: begin

                            if (ack_phase == 2'd0) begin

                                // ACK only if the address matches.
                                // Otherwise release SDA for NACK.

                                sda_ena <= addr_match;

                                ack_phase <= 2'd1;

                            end

                            else if (ack_phase == 2'd2) begin

                                // Finish address ACK clock.
                                sda_ena <= 1'b0;

                                ack_phase <= 2'd0;

                                if (addr_match) begin

                                    if (rw == 1'b0) begin

                                        // Write transaction:
                                        // Receive memory address next.

                                        state <= ST_RX_MEM_ADDR;

                                    end else begin

                                        // Read transaction:
                                        // Transmit from current memory
                                        // address register.

                                        read_data <=
                                            memory[mem_addr_reg];

                                        tx_bit_index <= 3'd7;

                                        // Prepare bit 7 (MSB).
                                        sda_ena <=
                                            !memory[mem_addr_reg][7];

                                        state <= ST_TX_READ_DATA;

                                    end

                                end else begin

                                    state <= ST_WAIT_STOP;

                                end

                            end

                        end

                        // -----------------------------------------
                        // MEMORY ADDRESS ACK
                        // -----------------------------------------

                        ST_ACK_MEM_ADDR: begin

                            if (ack_phase == 2'd0) begin

                                // ACK memory address byte.

                                sda_ena <= 1'b1;

                                ack_phase <= 2'd1;

                            end

                            else if (ack_phase == 2'd2) begin

                                // Release SDA after ACK.
                                //
                                // The master may now:
                                //   1. Send write data, or
                                //   2. Generate repeated START.

                                sda_ena <= 1'b0;

                                ack_phase <= 2'd0;

                                state <= ST_RX_WRITE_DATA;

                            end

                        end

                        // -----------------------------------------
                        // WRITE DATA ACK
                        // -----------------------------------------

                        ST_ACK_WRITE_DATA: begin

                            if (ack_phase == 2'd0) begin

                                // ACK received data byte.

                                sda_ena <= 1'b1;

                                ack_phase <= 2'd1;

                            end

                            else if (ack_phase == 2'd2) begin

                                // Release SDA after ACK.

                                sda_ena <= 1'b0;

                                ack_phase <= 2'd0;

                                // Ready for another data byte.
                                // The memory address was already
                                // incremented when the byte was stored.

                                state <= ST_RX_WRITE_DATA;

                            end

                        end

                        // -----------------------------------------
                        // TRANSMIT READ DATA
                        // -----------------------------------------

                        ST_TX_READ_DATA: begin

                            // The first bit is prepared when the
                            // slave address ACK finishes.
                            //
                            // Subsequent bits are prepared on
                            // falling SCL edges.

                            sda_ena <= !read_data[tx_bit_index];

                        end

                        // -----------------------------------------
                        // MASTER ACK/NACK
                        // -----------------------------------------

                        ST_MASTER_ACK: begin

                            if (master_ack) begin

                                // Master ACK:
                                // Send the next memory byte.

                                if (mem_addr_reg == MEM_DEPTH - 1) begin

                                    mem_addr_reg <= 8'd0;

                                    read_data <= memory[0];

                                    sda_ena <= !memory[0][7];

                                end else begin

                                    mem_addr_reg <=
                                        mem_addr_reg + 1'b1;

                                    read_data <=
                                        memory[mem_addr_reg + 1'b1];

                                    sda_ena <=
                                        !memory[mem_addr_reg + 1'b1][7];

                                end

                                tx_bit_index <= 3'd7;

                                state <= ST_TX_READ_DATA;

                            end else begin

                                // Master NACK:
                                // Release SDA and wait for STOP
                                // or repeated START.

                                sda_ena <= 1'b0;

                                state <= ST_WAIT_STOP;

                            end

                        end

                        default: begin
                        end

                    endcase

                end

            end

            // ====================================================
            // UPDATE PREVIOUS SIGNAL LEVELS
            // ====================================================

            prev_scl <= scl;
            prev_sda <= sda_in;

        end

    end

endmodule
