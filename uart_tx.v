module uart_tx #(
    parameter CLK_HZ = 50000000,  // Clock frequency
    parameter BIT_RATE = 9600,     // Baud rate
    parameter PAYLOAD_BITS = 8      // Number of bits in the payload
)(
    input               CLK,          // Clock signal
    input               reset,        // Asynchronous reset
    input               uart_tx_en,   // Transmit enable
    input [PAYLOAD_BITS-1:0] uart_tx_data, // Data to transmit
    output reg         uart_txd,     // UART transmit pin
    output reg         uart_tx_busy   // Indicates if transmission is in progress
);

localparam CLOCKS_PER_BIT = CLK_HZ / BIT_RATE;

reg [3:0] bit_index;
reg [10:0] shift_reg; // Shift register for transmitting data

always @(posedge CLK or negedge reset) begin
    if (!reset) begin
        bit_index <= 0;
        uart_txd <= 1; // Idle state
        uart_tx_busy <= 0;
    end else if (uart_tx_en && !uart_tx_busy) begin
        // Load the shift register with the start bit, data, and stop bit
        shift_reg <= {1'b1, uart_tx_data, 1'b0}; // Start bit (0), data, stop bit (1)
        bit_index <= 0;
        uart_tx_busy <= 1; // Set busy flag
    end else if (uart_tx_busy) begin
        if (bit_index < 11) begin
            uart_txd <= shift_reg[0]; // Transmit the current bit
            shift_reg <= {1'b1, shift_reg[10:1]}; // Shift left
            bit_index <= bit_index + 1; // Move to the next bit
        end else begin
            uart_tx_busy <= 0; // Clear busy flag when transmission is complete
            uart_txd <= 1; // Set to idle state
        end
    end
end

endmodule
