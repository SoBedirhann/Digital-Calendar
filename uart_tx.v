`timescale 1ns / 1ps

module uart_tx (
    input wire clk,          // Sistem saat sinyali
    input wire reset,        // Asenkron reset
    input wire tx_start,     // Veriyi gönderme ba?lang?c?
    input wire [7:0] tx_data,// Gönderilecek veri
    input en,
    output reg tx,           // UART seri ç?k?? (TX)

    output reg tx_busy       // Verici me?gul sinyali
);

    // Parametreler
    parameter CLOCK_FREQ = 100000000; // 100 MHz sistem saat frekans?
    parameter BAUD_RATE = 9600;       // Baud rate
    localparam BAUD_DIVISOR = CLOCK_FREQ / BAUD_RATE;
    
    // ?ç sinyaller ve registerlar
    reg [3:0] bit_index;      // Gönderilen bit indeksi
    reg [15:0] baud_counter;  // Baud rate için sayaç
    reg [9:0] tx_shift_reg;   // Gönderilecek veri + start/stop bitleri
    reg en_reg;
    // UART Transmitter FSM

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1'b1;             // Durdurma bitini gösterir
            tx_busy <= 1'b0;
            baud_counter <= 0;
            bit_index <= 0;
            tx_shift_reg <= 0;
        end else begin
            if (tx_start && !tx_busy && en) begin
                // Ba?lang?ç: Veriyi yükle ve ba?la
                tx_shift_reg <= {1'b1, tx_data, 1'b0}; // Stop bit (1), veri, ve start bit (0)
                tx_busy <= 1'b1;
                bit_index <= 0;
                baud_counter <= 0;  // Sayaç s?f?rlan?r, bit iletimini hemen ba?lat?r
            end

            if (tx_busy && en) begin
                if (baud_counter < BAUD_DIVISOR - 1) begin
                    baud_counter <= baud_counter + 1;
                end else begin
                    baud_counter <= 0;
                    tx <= tx_shift_reg[bit_index]; // S?radaki biti gönder
                    bit_index <= bit_index + 1;
                    
                    if (bit_index == 9) begin
                        tx_busy <= 1'b0; // Tüm bitler gönderildi?inde dur
                        bit_index <= 0;
                        tx <= 1'b1; // Hat inaktif halde (idle) duruma geçer
                    end
                end
            end
        end
    end
endmodule