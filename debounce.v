`timescale 1ns / 1ps

module debounce(
    input wire clk,          // Saat sinyali
    input wire reset,        // Reset sinyali
    input wire buton,        // Mekanik butondan gelen sinyal
    output reg temiz_sinyal  // Titreşimsiz (debounced) çıkış sinyali
);

    reg [15:0] sayac;        // Sayaç
    reg buton_durum;         // Geçici buton durumu

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sayac <= 0;
            buton_durum <= 0;
            temiz_sinyal <= 0;
        end else begin
            if (buton == buton_durum) begin
                if (sayac < 16'hFFFF) begin
                    sayac <= sayac + 1;
                end else begin
                    temiz_sinyal <= buton_durum; // Titreşimsiz çıkış sinyali güncellenir
                end
            end else begin
                sayac <= 0;             // Buton durumu değiştiğinde sayaç sıfırlanır
                buton_durum <= buton;   // Yeni buton durumu kaydedilir
            end
        end
    end
endmodule

