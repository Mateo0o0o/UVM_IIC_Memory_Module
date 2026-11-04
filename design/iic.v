module i2c_slave #(
    parameter logic [6:0] SLAVE_ADDR = 7'h42
)(
    input  logic       clk,
    input  logic       rst_n,

    // I2C interface
    input  logic       scl,
    inout  wire        sda,

    // User interface
    output logic [7:0] rx_data,
    output logic       rx_valid,

    input  logic [7:0] tx_data,
    output logic       tx_done
);

    typedef enum logic [2:0] {
        IDLE,
        ADDRESS,
        ACK_ADDR,
        WRITE_DATA,
        ACK_DATA,
        READ_DATA,
        MASTER_ACK
    } state_t;

    state_t state;

    logic [7:0] shift_reg;
    logic [2:0] bit_count;
    logic       rw;
    logic       sda_out;
    logic       sda_oe;

    logic scl_d, sda_d;
    logic start_cond, stop_cond;

    assign sda = sda_oe ? sda_out : 1'bz;

    // START and STOP detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_d <= 1'b1;
            sda_d <= 1'b1;
        end else begin
            scl_d <= scl;
            sda_d <= sda;
        end
    end

    assign start_cond = scl && sda_d && !sda;
    assign stop_cond  = scl && !sda_d && sda;

    // I2C state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            shift_reg <= 8'h00;
            bit_count <= 3'd0;
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
            tx_done   <= 1'b0;
            rw        <= 1'b0;
            sda_out   <= 1'b1;
            sda_oe    <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            tx_done  <= 1'b0;

            if (stop_cond) begin
                state  <= IDLE;
                sda_oe <= 1'b0;
            end
            else if (start_cond) begin
                state     <= ADDRESS;
                bit_count <= 3'd0;
                sda_oe    <= 1'b0;
            end
            else if (scl && !scl_d) begin
                case (state)

                    IDLE: begin
                    end

                    ADDRESS: begin
                        shift_reg <= {shift_reg[6:0], sda};

                        if (bit_count == 3'd7) begin
                            rw <= sda;
                            bit_count <= 3'd0;

                            if ({shift_reg[5:0], sda} == SLAVE_ADDR) begin
                                state <= ACK_ADDR;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end

                    ACK_ADDR: begin
                        sda_out <= 1'b0;
                        sda_oe  <= 1'b1;

                        if (rw)
                            state <= READ_DATA;
                        else
                            state <= WRITE_DATA;

                        bit_count <= 3'd0;
                    end

                    WRITE_DATA: begin
                        shift_reg <= {shift_reg[6:0], sda};

                        if (bit_count == 3'd7) begin
                            rx_data  <= {shift_reg[6:0], sda};
                            rx_valid <= 1'b1;
                            state    <= ACK_DATA;
                            bit_count <= 3'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end

                    ACK_DATA: begin
                        sda_out <= 1'b0;
                        sda_oe  <= 1'b1;
                        state   <= WRITE_DATA;
                    end

                    READ_DATA: begin
                        sda_out <= tx_data[7-bit_count];
                        sda_oe  <= 1'b1;

                        if (bit_count == 3'd7) begin
                            state <= MASTER_ACK;
                            bit_count <= 3'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end

                    MASTER_ACK: begin
                        sda_oe <= 1'b0;
                        tx_done <= 1'b1;

                        if (!sda)
                            state <= READ_DATA;
                        else
                            state <= IDLE;
                    end

                    default: state <= IDLE;

                endcase
            end
        end
    end

endmodule
