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

    // ------------------------------------------------------------
    // Parameters and internal declarations
    // ------------------------------------------------------------

    localparam int ADDR_WIDTH =
        (MEM_DEPTH <= 1) ? 1 : $clog2(MEM_DEPTH);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_ADDRESS,
        ST_ACK_ADDR,
        ST_WRITE_DATA,
        ST_ACK_WRITE,
        ST_READ_DATA,
        ST_MASTER_ACK,
        ST_WAIT_STOP
    } state_t;

    state_t state;

    logic [7:0] memory [0:MEM_DEPTH-1];

    logic [7:0] shift_reg;
    logic [7:0] read_data;

    logic [ADDR_WIDTH-1:0] mem_addr;

    logic [3:0] bit_count;

    logic rw;
    logic addr_match;

    logic ack_clock_seen;
    logic master_ack;

    // Previous signal levels for START/STOP detection
    logic prev_scl;
    logic prev_sda;

    integer i;

    // ------------------------------------------------------------
    // SDA output
    // ------------------------------------------------------------

    // Open-drain behavior:
    // sda_ena = 1 -> pull SDA low
    // sda_ena = 0 -> release SDA
    //
    // sda_out is always zero because the slave must never
    // actively drive the SDA line high.

    // assign sda_out = 1'b0;

    // ------------------------------------------------------------
    // Main I2C protocol logic
    // ------------------------------------------------------------

    // This is a behavioral, event-driven implementation for
    // simulation. Protocol data/state operations occur on SCL
    // edges. SDA transitions while SCL is high detect START/STOP.
    //
    // It intentionally has no independent system clock.

    always @(scl or sda_in or negedge rst_n) begin

        if (!rst_n) begin

            state           <= ST_IDLE;

            shift_reg       <= 8'h00;
            read_data       <= 8'h00;

            mem_addr        <= '0;
            bit_count       <= 4'd0;

            rw              <= 1'b0;
            addr_match      <= 1'b0;

            ack_clock_seen  <= 1'b0;
            master_ack      <= 1'b0;

            sda_ena         <= 1'b0;

            prev_scl        <= 1'b1;
            prev_sda        <= 1'b1;

            for (i = 0; i < MEM_DEPTH; i = i + 1)
                memory[i] <= 8'h00;

        end else begin

            // ----------------------------------------------------
            // START and STOP detection
            // ----------------------------------------------------

            // START: SDA transitions HIGH -> LOW while SCL HIGH
            // STOP : SDA transitions LOW -> HIGH while SCL HIGH

            if ((sda_in != prev_sda) && scl) begin

                if (prev_sda && !sda_in) begin

                    // START or repeated START
                    state          <= ST_ADDRESS;

                    shift_reg      <= 8'h00;
                    bit_count      <= 4'd0;

                    addr_match     <= 1'b0;
                    rw             <= 1'b0;

                    ack_clock_seen <= 1'b0;
                    master_ack     <= 1'b0;

                    sda_ena        <= 1'b0;

                end else if (!prev_sda && sda_in) begin

                    // STOP
                    state          <= ST_IDLE;

                    bit_count      <= 4'd0;
                    ack_clock_seen <= 1'b0;

                    sda_ena        <= 1'b0;

                end

            end

            // ----------------------------------------------------
            // SCL edge detection
            // ----------------------------------------------------

            else if (scl != prev_scl) begin

                // =================================================
                // SCL RISING EDGE
                // Sample incoming data from the master.
                // =================================================

                if (!prev_scl && scl) begin

                    case (state)

                        // -----------------------------------------
                        // Receive slave address + R/W bit
                        // -----------------------------------------

                        ST_ADDRESS: begin

                            shift_reg <= {
                                shift_reg[6:0],
                                sda_in
                            };

                            if (bit_count == 4'd7) begin

                                // Compare the received 7-bit
                                // address with the configured address.
                                addr_match <=
                                    ({shift_reg[6:0], sda_in} >> 1)
                                    == SLAVE_ADDR;

                                // Least significant bit is R/W.
                                rw <= sda_in;

                                bit_count <= 4'd0;

                                state <= ST_ACK_ADDR;

                                ack_clock_seen <= 1'b0;

                            end else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // Address ACK clock
                        // -----------------------------------------

                        ST_ACK_ADDR: begin

                            ack_clock_seen <= 1'b1;

                        end

                        // -----------------------------------------
                        // Receive memory write data
                        // -----------------------------------------

                        ST_WRITE_DATA: begin

                            shift_reg <= {
                                shift_reg[6:0],
                                sda_in
                            };

                            if (bit_count == 4'd7) begin

                                // Store received byte
                                memory[mem_addr] <= {
                                    shift_reg[6:0],
                                    sda_in
                                };

                                // Increment memory pointer
                                mem_addr <= mem_addr + 1'b1;

                                bit_count <= 4'd0;

                                state <= ST_ACK_WRITE;

                                ack_clock_seen <= 1'b0;

                            end else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        // -----------------------------------------
                        // Write ACK clock
                        // -----------------------------------------

                        ST_ACK_WRITE: begin

                            ack_clock_seen <= 1'b1;

                        end

                        // -----------------------------------------
                        // Slave transmits data
                        // -----------------------------------------

                        ST_READ_DATA: begin

                            // Data is driven on SCL falling edges.
                            // Nothing needs to change here.
                        end

                        // -----------------------------------------
                        // Master ACK/NACK after a read byte
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
                // Update slave SDA output.
                // =================================================

                else begin

                    case (state)

                        // -----------------------------------------
                        // Address ACK/NACK
                        // -----------------------------------------

                        ST_ACK_ADDR: begin

                            if (!ack_clock_seen) begin

                                // Ninth clock begins:
                                // ACK if address matches.
                                sda_ena <= addr_match;

                            end else begin

                                // Ninth clock completed.
                                // Release SDA.
                                sda_ena <= 1'b0;

                                ack_clock_seen <= 1'b0;

                                if (addr_match) begin

                                    if (rw == 1'b0) begin

                                        // Master writes to slave
                                        state <= ST_WRITE_DATA;

                                    end else begin

                                        // Master reads from slave
                                        read_data <= memory[mem_addr];

                                        bit_count <= 4'd0;

                                        // Prepare first data bit.
                                        // Pull low only if MSB = 0.
                                        sda_ena <= !memory[mem_addr][7];

                                        state <= ST_READ_DATA;

                                    end

                                end else begin

                                    // Address did not match.
                                    state <= ST_WAIT_STOP;

                                end

                            end

                        end

                        // -----------------------------------------
                        // Write data ACK
                        // -----------------------------------------

                        ST_ACK_WRITE: begin

                            if (!ack_clock_seen) begin

                                // Pull SDA low for ACK.
                                sda_ena <= 1'b1;

                            end else begin

                                // Release SDA after ACK clock.
                                sda_ena <= 1'b0;

                                ack_clock_seen <= 1'b0;

                                state <= ST_WRITE_DATA;

                            end

                        end

                        // -----------------------------------------
                        // Read data bits
                        // -----------------------------------------

                        ST_READ_DATA: begin

                            if (bit_count == 4'd7) begin

                                // All 8 bits have been transmitted.
                                // Release SDA for master's ACK/NACK.
                                sda_ena <= 1'b0;

                                state <= ST_MASTER_ACK;

                            end else begin

                                // Prepare the next data bit.
                                bit_count <= bit_count + 1'b1;

                                // Pull low when the next bit is zero.
                                sda_ena <=  1;
                                sda_out <=  read_data[6 - bit_count];

                            end

                        end

                        // -----------------------------------------
                        // Master ACK/NACK handling
                        // -----------------------------------------

                        ST_MASTER_ACK: begin

                            if (master_ack) begin

                                // Master ACK:
                                // Continue transmitting next byte.

                                read_data <= memory[mem_addr];

                                mem_addr <= mem_addr + 1'b1;

                                bit_count <= 4'd0;

                                // Prepare MSB of next byte.
                                sda_ena <= !memory[mem_addr][7];

                                state <= ST_READ_DATA;

                            end else begin

                                // Master NACK:
                                // End read transmission.
                                // Wait for STOP or repeated START.
                                sda_ena <= 1'b0;

                                state <= ST_WAIT_STOP;

                            end

                        end

                        default: begin
                        end

                    endcase

                end

            end

            // Save current bus levels for edge detection.
            prev_scl <= scl;
            prev_sda <= sda_in;

        end

    end

endmodule