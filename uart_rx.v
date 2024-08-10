module uart_rx (
    input               CLK,           // Clock signal
    input               reset,         // Asynchronous reset
    input               uart_rxd,      // UART receive pin
    input               uart_rx_en,    // Receive enable
    output reg          uart_rx_valid, // Valid data received
    output reg [7:0]    uart_rx_data,  // Received data
    output reg          uart_rx_break  // Break condition
);

parameter CLK_HZ = 100000000; // Clock frequency
parameter BIT_RATE = 9600;    // Baud rate
parameter CLOCKS_PER_BIT = CLK_HZ / BIT_RATE;
localparam TOTAL_BITS = 1 + 8 + 1; // Start bit + 8 Data bits + Stop bit

reg [$clog2(CLOCKS_PER_BIT)-1:0] clock_count; // Counter for bit timing
reg [3:0] bit_index;
reg [TOTAL_BITS-1:0] shift_reg; // Shift register to hold incoming data

reg sampling; // State flag for bit sampling

always @(posedge CLK or negedge reset) begin
    if (!reset) begin
        bit_index <= 0;
        clock_count <= 0;
        uart_rx_valid <= 0;
        uart_rx_data <= 0;
        uart_rx_break <= 0;
        shift_reg <= 0;
        sampling <= 0;
    end else if (uart_rx_en) begin
        if (!sampling) begin
            // Detect start bit (low)
            if (!uart_rxd) begin
                sampling <= 1;
                clock_count <= 0;
                bit_index <= 0;
            end
        end else begin
            if (clock_count < CLOCKS_PER_BIT - 1) begin
                clock_count <= clock_count + 1;
            end else begin
                clock_count <= 0;
                if (bit_index < TOTAL_BITS) begin
                    shift_reg <= {uart_rxd, shift_reg[TOTAL_BITS-1:1]}; // Shift in the new bit
                    bit_index <= bit_index + 1;
                end else begin
                    sampling <= 0;
                    if (shift_reg[0] == 0 && shift_reg[TOTAL_BITS-1] == 1) begin
                        // If start bit is 0 and stop bit is 1, valid data received
                        uart_rx_data <= shift_reg[8:1]; // Extract data bits
                        uart_rx_valid <= 1;
                    end else begin
                        uart_rx_break <= 1; // Break condition if stop bit is not valid
                    end
                end
            end
        end
    end else begin
        uart_rx_valid <= 0; // Clear valid flag when not enabled
        uart_rx_break <= 0; // Clear break condition
    end
end

endmodule
