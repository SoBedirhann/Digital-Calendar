`timescale 1ns / 1ps

module vga_display(
    input wire clk_148_5MHz,   // 148.5 MHz saat sinyali
    input wire reset,          // Asenkron reset
    input wire [31:0] pixel_x, // Yatay piksel pozisyonu
    input wire [31:0] pixel_y, // Dikey piksel pozisyonu
    input wire [3:0] yil_binlik, // Y?l?n binlik basama??
    input wire [3:0] yil_yuzluk, // Y?l?n yüzlük basama??
    input wire [3:0] yil_onluk,  // Y?l?n onluk basama??
    input wire [3:0] yil_birlik, // Y?l?n birlik basama??
    input wire ay_onluk,           // Ay?n onluk basama??
    input wire [3:0] ay_birlik,    // Ay?n birlik basama??
    input wire [2:0] gun_onluk,      // Gün onluk basama??
    input wire [3:0] gun_birlik,     // Gün birlik basama??
    input wire [2:0] saat_onluk,       // Saatin onluk basama??
    input wire [3:0] saat_birlik,      // Saatin birlik basama??
    input wire [2:0] dakika_onluk,       // Dakikan?n onluk basama??
    input wire [3:0] dakika_birlik,      // Dakikan?n birlik basama??
    input wire [2:0] saniye_onluk,         // Saniyenin onluk basama??
    input wire [3:0] saniye_birlik,        // Saniyenin birlik basama??
    input wire video_on,        // Video etkin sinyali
    output reg [2:0] rgb        // RGB ç?k???
);

    // Karakter ROM modülü için sinyaller
    reg [3:0] char_code;       // Gösterilecek karakterin kodu
    reg [4:0] row;             // Karakterin sat?r indeksi (0-31)
    wire [31:0] pixel_row;     // Karakterin o sat?rdaki piksel verisi

    // Karakter ROM instansiyonu
    char_rom char_rom_inst (
        .char_code(char_code),
        .row(pixel_y[4:0]),   // Yaln?zca alt 5 biti kullan
        .pixel_row(pixel_row)
    );

    // Piksel blo?unda her karakter 32x32 piksel olarak ele al?n?r
    localparam CHAR_WIDTH = 32;
    localparam CHAR_HEIGHT = 32;

    // Hangi karakterin ekranda oldu?unu belirlemek için alan
    always @(posedge clk_148_5MHz) begin
        if (video_on) begin
            // Sat?r ve sütun de?erlerini hesapla
            row <= pixel_y[4:0];  // Sat?r indeksi (0-31)
            
            if (pixel_x >= 0 && pixel_x < CHAR_WIDTH) begin
                char_code <= gun_onluk;  // Günün onluk basama??
            end 
            else if (pixel_x >= CHAR_WIDTH && pixel_x < 2*CHAR_WIDTH) begin
                char_code <= gun_birlik;  // Günün birlik basama??
            end 
            else if (pixel_x >= 2*CHAR_WIDTH && pixel_x < 3*CHAR_WIDTH) begin
                char_code <= 4'hB;  // Bo?luk (" . ")
            end 
            else if (pixel_x >= 3*CHAR_WIDTH && pixel_x < 4*CHAR_WIDTH) begin
                char_code <= ay_onluk;  // Ay?n onluk basama??
            end 
            else if (pixel_x >= 4*CHAR_WIDTH && pixel_x < 5*CHAR_WIDTH) begin
                char_code <= ay_birlik;  // Ay?n birlik basama??
            end 
            else if (pixel_x >= 5*CHAR_WIDTH && pixel_x < 6*CHAR_WIDTH) begin
                char_code <= 4'hB;  // Bo?luk (" . ")
            end 
            else if (pixel_x >= 6*CHAR_WIDTH && pixel_x < 7*CHAR_WIDTH) begin
                char_code <= yil_binlik;  // Y?l?n binlik basama??
            end 
            else if (pixel_x >= 7*CHAR_WIDTH && pixel_x < 8*CHAR_WIDTH) begin
                char_code <= yil_yuzluk;  // Y?l?n yüzlük basama??
            end 
            else if (pixel_x >= 8*CHAR_WIDTH && pixel_x < 9*CHAR_WIDTH) begin
                char_code <= yil_onluk;  // Y?l?n onluk basama??
            end
            else if (pixel_x >= 9*CHAR_WIDTH && pixel_x < 10*CHAR_WIDTH) begin
                char_code <= yil_birlik;  // Y?l?n birlik basama??
            end
            else if (pixel_x >= 10*CHAR_WIDTH && pixel_x < 11*CHAR_WIDTH) begin
                char_code <= 4'hB;  // Bo?luk (" . ")
            end 
            else if (pixel_x >= 11*CHAR_WIDTH && pixel_x < 12*CHAR_WIDTH) begin
                char_code <= saat_onluk;  // Saatin onluk basama??
            end
            else if (pixel_x >= 12*CHAR_WIDTH && pixel_x < 13*CHAR_WIDTH) begin
                char_code <= saat_birlik;  // Saatin birlik basama??
            end
            else if (pixel_x >= 13*CHAR_WIDTH && pixel_x < 14*CHAR_WIDTH) begin
                char_code <= 4'hA;  // " : "
            end
            else if (pixel_x >= 14*CHAR_WIDTH && pixel_x < 15*CHAR_WIDTH) begin
                char_code <= dakika_onluk;  // Dakikan?n onluk basama??
            end
            else if (pixel_x >= 15*CHAR_WIDTH && pixel_x < 16*CHAR_WIDTH) begin
                char_code <= dakika_birlik;  // Dakikan?n birlik basama??
            end
            else if (pixel_x >= 16*CHAR_WIDTH && pixel_x < 17*CHAR_WIDTH) begin
                char_code <= 4'hA;  // " : "
            end
            else if (pixel_x >= 17*CHAR_WIDTH && pixel_x < 18*CHAR_WIDTH) begin
                char_code <= saniye_onluk;  // Saniyenin onluk basama??
            end
            else if (pixel_x >= 18*CHAR_WIDTH && pixel_x < 19*CHAR_WIDTH) begin
                char_code <= saniye_birlik;  // Saniyenin birlik basama??
            end
            else begin
                char_code <= 4'hF;  // Bo? alan için
            end

            // E?er pixel_x ve pixel_y karakterin alan? içinde ise, o pikseli çizin
            if (pixel_row[~pixel_x[4:0]]) begin
                rgb <= 3'b111;  // Beyaz renk
            end 
            else begin
                rgb <= 3'b000;  // Siyah renk
            end
        end 
        else begin
            rgb <= 3'b000;  // Ekran d???ndaysan?z, siyah renk gösterin
        end
    end

endmodule