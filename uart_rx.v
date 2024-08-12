`timescale 1ns / 1ps

module uart_rx (
    input wire clk,          // Sistem saat sinyali
    input wire reset,        // Asenkron reset
    input wire rx,           // UART seri giri? (RX)
    output reg [7:0] rx_data,// Al?nan veri
    output reg rx_ready      // Veri alma i?lemi tamamland? sinyali
);

    // Parametreler
    parameter CLOCK_FREQ = 100000000; // 100 MHz sistem saat frekans?
    parameter BAUD_RATE = 9600;       // Baud rate
    localparam BAUD_DIVISOR = CLOCK_FREQ / BAUD_RATE;
    localparam HALF_BAUD_DIVISOR = (BAUD_DIVISOR-1) / 2;

    // ?ç sinyaller ve registerlar
    reg [3:0] bit_index;       // Al?nan bit indeksi
    reg [15:0] baud_counter;   // Baud rate için sayaç
    reg [7:0] rx_shift_reg;    // Al?nan veriyi depolamak için kayd?rma register?
    reg rx_busy;               // Al?c? me?gul sinyali
    reg sample;                // Orta nokta örnekleme sinyali

    // UART Receiver FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_ready <= 1'b0;
            rx_busy <= 1'b0;
            baud_counter <= 16'd0;
            bit_index <= 4'd0;
            rx_shift_reg <= 8'd0;
            sample <= 1'b0;
        end else begin
            if (!rx_busy && !rx) begin
                // Start biti alg?land?
                rx_busy <= 1'b1;
                baud_counter <= 16'd0;
                bit_index <= 4'd0;
                sample <= 1'b0;
            end
            
            if (rx_busy) begin
                if (baud_counter < BAUD_DIVISOR - 1) begin
                    baud_counter <= baud_counter + 1;
                end else begin
                    baud_counter <= 16'd0;
                    
                    if (!sample) begin
                        // Start bitinin ortas?nda örnekleme
                        if (bit_index == 0) begin
                            sample <= 1'b1;
                        end
                    end else begin
                        if (bit_index < 8) begin
                            // Veri bitlerini al
                            rx_shift_reg[bit_index] <= rx;
                            bit_index <= bit_index + 1;
                        end else begin
                            // Stop bitini kontrol et
                            if (rx == 1'b1) begin
                                rx_data <= rx_shift_reg;
                                rx_ready <= 1'b1;
                            end
                            rx_busy <= 1'b0; // Al?m i?lemi tamamland?
                        end
                    end
                end
            end else begin
                rx_ready <= 1'b0; // Veri haz?r sinyalini s?f?rla
            end
        end
    end
endmodule