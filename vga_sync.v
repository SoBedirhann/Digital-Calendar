`timescale 1ns / 1ps
module vga_sync(
    input wire clk_148_5MHz,  // 148.5 MHz saat sinyali
    input wire reset,         // Asenkron reset
    output reg hsync,         // Yatay senkronizasyon sinyali
    output reg vsync,         // Dikey senkronizasyon sinyali
    output wire [31:0] pixel_x, // Yatay piksel pozisyonu
    output wire [31:0] pixel_y, // Dikey piksel pozisyonu
    output wire video_on      // Video etkin sinyali
);
    
    // 1080p çözünürlük için VGA zamanlama parametreleri
    localparam H_DISPLAY = 1920;  // Görüntülenen piksel say?s?
    localparam H_FRONT  = 88;     // Yatay ön bo?luk
    localparam H_SYNC   = 44;     // Yatay senkronizasyon süresi
    localparam H_BACK   = 148;    // Yatay geri bo?luk
    localparam H_TOTAL  = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;

    localparam V_DISPLAY = 1080;  // Görüntülenen sat?r say?s?
    localparam V_FRONT  = 4;      // Dikey ön bo?luk
    localparam V_SYNC   = 5;      // Dikey senkronizasyon süresi
    localparam V_BACK   = 36;     // Dikey geri bo?luk
    localparam V_TOTAL  = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;

    reg [31:0] h_count;  // Yatay piksel sayac?
    reg [31:0] v_count;  // Dikey sat?r sayac?

    // Hsync ve Vsync sinyalleri üretimi
    always @(posedge clk_148_5MHz or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
            hsync <= 1;
            vsync <= 1;
        end else begin
            // Yatay sayac? art?r
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;

                // Dikey sayac? art?r
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end

            // Hsync üretimi
            if (h_count >= H_DISPLAY + H_FRONT && h_count < H_DISPLAY + H_FRONT + H_SYNC) begin
                hsync <= 0;
            end else begin
                hsync <= 1;
            end

            // Vsync üretimi
            if (v_count >= V_DISPLAY + V_FRONT && v_count < V_DISPLAY + V_FRONT + V_SYNC) begin
                vsync <= 0;
            end else begin
                vsync <= 1;
            end
        end
    end

    // Pixel pozisyonlar? ve video etkin sinyali
    assign pixel_x = (h_count < H_DISPLAY) ? h_count : 0;
    assign pixel_y = (v_count < V_DISPLAY) ? v_count : 0;
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

endmodule