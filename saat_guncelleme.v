`timescale 1ns / 1ps

module saat_guncelleme(
    input CLK, reset, hiz_degisikligi,
    input [4:0] butonlar,
    input rx,
    output tx,
    output reg [5:0] led_gosterimi,
    output reg [6:0] seg,  // 7-segment display için segment çıkışları
    output reg dp,         // Ondalık nokta çıkışı
    output reg [3:0] an    // Aktif 7-segment basamağı
);
    
    // Ba?lang?ç de?erleri
    reg [5:0] saniye = 5'd0, saniye_sonraki;
    reg [5:0] dakika = 5'd30, dakika_sonraki;
    reg [4:0] saat = 5'd18, saat_sonraki;
    reg [4:0] gun = 5'd30, gun_sonraki;
    reg [3:0] ay = 4'd7, ay_sonraki;
    reg [11:0] yil = 12'd2024, yil_sonraki;
    reg calisma_durumu = 1'd1; 
    reg [29:0] sayac = 29'd0, sayac_sonraki;
    reg [6:0] hiz_katsayisi = 7'd1, hiz_katsayisi_sonraki; 
    localparam BIR_SANIYE = 100000000;

    // UART RX için sinyaller
    wire [7:0] uart_rx_data;
    wire uart_rx_valid;
    wire uart_rx_break;

    // UART RX modülünün başlatılması
    uart_rx uart_receiver (
        .CLK(CLK),
        .reset(reset),
        .uart_rxd(rx),
        .uart_rx_en(1'b1),
        .uart_rx_break(uart_rx_break),
        .uart_rx_valid(uart_rx_valid),
        .uart_rx_data(uart_rx_data)
    );

    // UART TX modülünün eklenmesi
    wire uart_tx_busy;
    reg uart_tx_en;
    reg [7:0] uart_tx_data;
    reg [1:0] digit_select = 2'b00;
    
    uart_tx #(
        .BIT_RATE(9600),
        .CLK_HZ(50_000_000),
        .PAYLOAD_BITS(8)
    ) uart_transmitter (
        .CLK(CLK),
        .reset(reset),
        .uart_tx_en(uart_tx_en),
        .uart_tx_data(uart_tx_data),
        .uart_txd(tx),
        .uart_tx_busy(uart_tx_busy)
    );
    
    always @* begin
        // Varsay?lan atamalar
        saniye_sonraki = saniye;
        led_gosterimi = saniye;
        dakika_sonraki = dakika;
        saat_sonraki = saat;
        gun_sonraki = gun;
        ay_sonraki = ay;
        yil_sonraki = yil;
        calisma_durumu = calisma_durumu;
        sayac_sonraki = sayac + 1;
        hiz_katsayisi_sonraki = hiz_katsayisi;

        // Durdurma-ba?latma i?lemi
        if (butonlar[4]) 
            calisma_durumu = ~calisma_durumu;

        // Ayarlama yap?lmas? için saat durmu? olmal?
        if (~calisma_durumu) begin
            if (butonlar[0]) begin
                saat_sonraki = (saat < 23) ? (saat + 1) : 0;
                if (saat == 0) begin 
                    gun_sonraki = gun + 1;
                    if (gun >= 31) begin
                        gun_sonraki = 1;
                        ay_sonraki = ay + 1;
                        if (ay >= 12) begin
                            ay_sonraki = 1;
                            yil_sonraki = yil + 1;
                        end
                    end                       
                end
            end
            if (butonlar[1]) begin
                saat_sonraki = (saat > 0) ? (saat - 1) : 23;
                if (saat == 23) begin
                    gun_sonraki = gun - 1;
                    if (gun == 0) begin
                        gun_sonraki = 31;
                        ay_sonraki = ay - 1;
                        if (ay == 0) begin
                            ay_sonraki = 12;
                            yil_sonraki = yil - 1;
                        end
                    end
                end
            end
            if (butonlar[2]) begin
                dakika_sonraki = (dakika < 59) ? (dakika + 1) : 0; 
                if (dakika == 0) begin
                    saat_sonraki = saat + 1;
                    if (saat >= 24) begin
                        saat_sonraki = 0;
                        gun_sonraki = gun + 1;
                        if (gun >= 31) begin
                            gun_sonraki = 1;
                            ay_sonraki = ay + 1;
                            if (ay >= 12) begin
                                ay_sonraki = 1;
                                yil_sonraki = yil + 1;
                            end
                        end
                    end
                end
            end
            if (butonlar[3]) begin
                dakika_sonraki = (dakika > 0) ? (dakika - 1) : 59;
                if (dakika == 59) begin
                    saat_sonraki = saat - 1;
                    if (saat == 23) begin
                        gun_sonraki = gun - 1;
                        if (gun == 0) begin
                            gun_sonraki = 31;
                            ay_sonraki = ay - 1;
                            if (ay == 0) begin
                                ay_sonraki = 12;
                                yil_sonraki = yil - 1;
                            end
                        end
                    end
                end 
            end
        end 
        if (calisma_durumu && (butonlar[0] || butonlar[1] || butonlar[2] || butonlar[3])) begin
            $display("SAAT CALISIYOR IKEN DUZENLEME YAPAMAZSINIZ.");
        end
        
        // Saati h?zland?rma (2 kat h?zland?r?r)
        if (hiz_degisikligi) begin
            hiz_katsayisi_sonraki = hiz_katsayisi * 2;
        end else begin
            hiz_katsayisi = 1;
        end
        
        // Durdurulmam??sa devam etsin
        if (calisma_durumu) begin    
            if (sayac >= (BIR_SANIYE / hiz_katsayisi)) begin // h?z katsay?s?na göre says?n
                sayac_sonraki = 0;
                saniye_sonraki = saniye + 1;
                $display("Saat: %d, Dakika: %d, Saniye: %d", saat, dakika, saniye);
                if (saniye >= 60) begin 
                    saniye_sonraki = 0;
                    dakika_sonraki = dakika + 1;
                    if (dakika >= 60) begin 
                        dakika_sonraki = 0;
                        saat_sonraki = saat + 1;
                        if (saat >= 24) begin 
                            saat_sonraki = 0;
                            gun_sonraki = gun + 1;
                            if (gun >= 31) begin 
                                gun_sonraki = 1;
                                ay_sonraki = ay + 1;
                                if (ay >= 12) begin
                                    ay_sonraki = 1;
                                    yil_sonraki = yil + 1;
                                end
                            end                       
                        end
                    end
                end
            end
        end
         case(digit_select)
            2'b00: begin
                seg = yedi_parcali_gosterim(saat_onluk_value); // Saat onluk
                an = 4'b1110; // İlk 7-segment aktif
                dp = 1'b1; // Ondalık noktası kapalı
            end
            2'b01: begin
                seg = yedi_parcali_gosterim(saat_birlik_value); // Saat birlik
                an = 4'b1101; // İkinci 7-segment aktif
                dp = 1'b1;
            end
            2'b10: begin
                seg = yedi_parcali_gosterim(dakika_onluk_value); // Dakika onluk
                an = 4'b1011; // Üçüncü 7-segment aktif
                dp = 1'b1;
            end
            2'b11: begin
                seg = yedi_parcali_gosterim(dakika_birlik_value); // Dakika birlik
                an = 4'b0111; // Dördüncü 7-segment aktif
                dp = 1'b1;
            end
        endcase
    end
    // Multiplexing için değişkenler
    
    reg [3:0] saat_onluk_value, saat_birlik_value, dakika_onluk_value, dakika_birlik_value;

    // 7-segment gösterim verilerini güncelleme
    always @* begin
        saat_onluk_value = (saat / 10);
        saat_birlik_value = (saat % 10);
        dakika_onluk_value = (dakika / 10);
        dakika_birlik_value = (dakika % 10);
    end

    // 7-segment gösterim için fonksiyon
    function [6:0] yedi_parcali_gosterim;
        input [3:0] value;
        begin
            case (value)
                4'd0: yedi_parcali_gosterim = 7'b0000001; // '0' göster
                4'd1: yedi_parcali_gosterim = 7'b1001111; // '1' göster
                4'd2: yedi_parcali_gosterim = 7'b0010010; // '2' göster
                4'd3: yedi_parcali_gosterim = 7'b0000110; // '3' göster
                4'd4: yedi_parcali_gosterim = 7'b1001100; // '4' göster
                4'd5: yedi_parcali_gosterim = 7'b0100100; // '5' göster
                4'd6: yedi_parcali_gosterim = 7'b0100000; // '6' göster
                4'd7: yedi_parcali_gosterim = 7'b0001111; // '7' göster
                4'd8: yedi_parcali_gosterim = 7'b0000000; // '8' göster
                4'd9: yedi_parcali_gosterim = 7'b0000100; // '9' göster
                default: yedi_parcali_gosterim = 7'b1111111; // Kapalı
            endcase
        end
    endfunction

    // Clock bölme ve basamak seçimi için
    always @(posedge CLK or posedge reset) begin
        if (reset) begin
            digit_select <= 2'b00; // Reset digit select
        end else begin
            digit_select <= digit_select + 1; // Her saat dalgasında basamağı değiştir
        end
    end
endmodule
