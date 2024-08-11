`timescale 1ns / 1ps

module saat_guncelleme(
    input CLK, reset, hiz_degisikligi,
    input [4:0] butonlar,
    input [5:0] saniye_ayari,
    input rx,
    output tx,
    output reg [5:0] led_gosterimi, // saniye yani
    output [0:6] seg,  // 7-segment display icin segment cikislari
    output reg dp,     // Ondalik nokta cikisi
    output [3:0] an    // Aktif 7-segment basamagi
);

    // baslangic degerleri
    reg [5:0] saniye_sonraki;
    reg [5:0] dakika = 6'd30, dakika_sonraki;
    reg [4:0] saat = 5'd18, saat_sonraki;
    reg [4:0] gun = 5'd30, gun_sonraki;
    reg [3:0] ay = 4'd7, ay_sonraki;
    reg [11:0] yil = 12'd2024, yil_sonraki;
    

    reg calisma_durumu = 1'd1; 

    reg [29:0] sayac = 30'd0, sayac_sonraki;

    reg [12:0] hiz_katsayisi = 13'd1, hiz_katsayisi_sonraki; 

    localparam BIR_SANIYE = 100000000;
    
    // basamaklarina ayirma islemi
    reg[3:0] deger = 4'd0, deger_sonraki;
    reg [3:0] saat_birlik_deger , dakika_birlik_deger, gun_birlik_deger, saniye_onluk_deger, saniye_birlik_deger;
    reg [3:0] yil_binlik_deger, yil_yuzluk_deger, yil_onluk_deger, yil_birlik_deger, ay_birlik_deger;
    reg [2:0] saat_onluk_deger, dakika_onluk_deger, gun_onluk_deger;
    reg ay_onluk_deger;
    
    
    wire temiz_sinyal_saat_arttir;
    wire temiz_sinyal_saat_azalt;
    wire temiz_sinyal_dakika_arttir;
    wire temiz_sinyal_dakika_azalt;
    wire temiz_sinyal_durdur_baslat;
    
    // Önceki temiz sinyaller
    reg temiz_sinyal_onceki_saat_arttir;
    reg temiz_sinyal_onceki_saat_azalt;
    reg temiz_sinyal_onceki_dakika_arttir;
    reg temiz_sinyal_onceki_dakika_azalt;
    reg temiz_sinyal_onceki_durdur_baslat;
    
    // Debounce modüllerini ekliyoruz
    debounce debounce_saat_arttir(.clk(CLK), .reset(reset), .buton(butonlar[0]), .temiz_sinyal(temiz_sinyal_saat_arttir));
    debounce debounce_saat_azalt(.clk(CLK), .reset(reset), .buton(butonlar[1]), .temiz_sinyal(temiz_sinyal_saat_azalt));
    debounce debounce_dakika_arttir(.clk(CLK), .reset(reset), .buton(butonlar[2]), .temiz_sinyal(temiz_sinyal_dakika_arttir));
    debounce debounce_dakika_azalt(.clk(CLK), .reset(reset), .buton(butonlar[3]), .temiz_sinyal(temiz_sinyal_dakika_azalt));
    debounce debounce_durdur_baslat(.clk(CLK), .reset(reset), .buton(butonlar[4]), .temiz_sinyal(temiz_sinyal_durdur_baslat));
    
        // Clock frequency in hertz.
    parameter CLK_HZ = 100000000;
    parameter BIT_RATE = 9600;
    parameter PAYLOAD_BITS = 8;
    
    wire [PAYLOAD_BITS-1:0] uart_rx_data;
    wire uart_rx_valid;
    wire uart_rx_break;
    
    wire uart_tx_busy;
    reg [PAYLOAD_BITS-1:0] uart_tx_data;
    reg uart_tx_en;

//    assign uart_tx_data = uart_rx_data;
//    assign uart_tx_en   = uart_rx_valid;
    
    reg [PAYLOAD_BITS-1:0] tx_data_reg;
    reg tx_en_reg;
    reg[4:0] sira = 5'd0;
    
    uart_rx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ  (CLK_HZ  )
    ) i_uart_rx(
    .clk(CLK), // Top level system clock input.
    .resetn (reset), // Asynchronous active low reset.
    .uart_rxd (rx), // UART Recieve pin.
    .uart_rx_en (1'b1), // Recieve enable
    .uart_rx_break (uart_rx_break), // Did we get a BREAK message?
    .uart_rx_valid (uart_rx_valid), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data)  // The recieved data.
    );
    
    //
    // UART Transmitter module.
    //
    uart_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ  (CLK_HZ  )
    ) i_uart_tx(
    .clk (CLK),
    .resetn (reset),
    .uart_txd (tx),
    .uart_tx_en (uart_tx_en),
    .uart_tx_busy (uart_tx_busy),
    .uart_tx_data (uart_tx_data) 
    );    
    
    always @* begin    
        // Varsayilan atamalar
        saniye_sonraki = led_gosterimi;
        dakika_sonraki = dakika;
        saat_sonraki = saat;
        gun_sonraki = gun;
        ay_sonraki = ay;
        yil_sonraki = yil;
        sayac_sonraki = sayac + 1;

        hiz_katsayisi_sonraki = hiz_katsayisi;
        
        uart_tx_data = tx_data_reg;
        uart_tx_en = tx_en_reg;
        
        if(hiz_degisikligi) begin
            if(hiz_katsayisi < 8192) begin
                hiz_katsayisi_sonraki = hiz_katsayisi + 1;
            end
        end else begin
            hiz_katsayisi_sonraki = 1;
        end

        // ayarlama yapilmasi icin saat durmus olmali
        // bu kisimda yorum satirina aldigimiz yerler istenen olaya gore degisir. 
        // eger saat ve dakikanin degismesiyle diger bolumler de degisecekse yorum satirlari kaldirilir.
        // saati arttirma
        if (temiz_sinyal_saat_arttir && ~temiz_sinyal_onceki_saat_arttir && ~calisma_durumu) begin
            saat_sonraki <= saat + 1;
            if (saat == 23) begin 
                saat_sonraki <= 0;
//                gun_sonraki <= gun + 1;
//                if (gun == 31) begin
//                    gun_sonraki <= 1;
//                    ay_sonraki <= ay + 1;
//                    if (ay == 12) begin
//                        ay_sonraki <= 1;
//                        yil_sonraki <= yil + 1;
//                    end
//                end                       
            end
        end
        
        //saati azaltma
        if (temiz_sinyal_saat_azalt && ~temiz_sinyal_onceki_saat_azalt && ~calisma_durumu) begin
            saat_sonraki <= saat - 1;
            if (saat == 0) begin
                saat_sonraki <= 23;
//                gun_sonraki <= gun - 1;
//                if (gun == 1) begin
//                    gun_sonraki <= 31;
//                    ay_sonraki <= ay - 1;
//                    if (ay == 1) begin
//                        ay_sonraki <= 12;
//                        yil_sonraki <= yil - 1;
//                    end
//                end
            end
        end

        // dakikayi arttirma
        if (temiz_sinyal_dakika_arttir && ~temiz_sinyal_onceki_dakika_arttir && ~calisma_durumu) begin
            dakika_sonraki <= dakika + 1; 
            if (dakika == 59) begin
                dakika_sonraki <= 0;
//                saat_sonraki <= saat + 1;
//                if (saat == 23) begin
//                    saat_sonraki <= 0;
//                    gun_sonraki <= gun + 1;
//                    if (gun == 31) begin
//                        gun_sonraki <= 1;
//                        ay_sonraki <= ay + 1;
//                        if (ay == 12) begin
//                            ay_sonraki <= 1;
//                            yil_sonraki <= yil + 1;
//                        end
//                    end
//                end
            end
        end

        // dakikayi azaltma
        if (temiz_sinyal_dakika_azalt && ~temiz_sinyal_onceki_dakika_azalt && ~calisma_durumu) begin
            dakika_sonraki <= dakika - 1;
            if (dakika == 0) begin
                dakika_sonraki <= 59;
//                saat_sonraki <= saat - 1;
//                if (saat == 0) begin
//                    saat_sonraki <= 23;
//                    gun_sonraki <= gun - 1;
//                    if (gun == 1) begin
//                        gun_sonraki <= 31;
//                        ay_sonraki <= ay - 1;
//                        if (ay == 1) begin
//                            ay_sonraki = 12;
//                            yil_sonraki = yil - 1;
//                        end
//                    end
//                end
            end 
        end
        
        // durdurulmamissa devam etsin
        if (calisma_durumu) begin    
            if (sayac >= (BIR_SANIYE * hiz_katsayisi)) begin // hiz katsayisina göre saysin
                sayac_sonraki = 0;
                saniye_sonraki = led_gosterimi + 1;
                if (led_gosterimi >= 59) begin 
                    saniye_sonraki = 0;
                    dakika_sonraki = dakika + 1;
                    if (dakika == 59) begin 
                        dakika_sonraki = 0;
                        saat_sonraki = saat + 1;
                        if (saat == 23) begin 
                            saat_sonraki = 0;
                            gun_sonraki = gun + 1;
                            if (gun == 31) begin 
                                gun_sonraki = 1;
                                ay_sonraki = ay + 1;
                                if (ay == 12) begin
                                    ay_sonraki = 1;
                                    yil_sonraki = yil + 1;
                                end
                            end                       
                        end
                    end
                end
            end
        end else begin
            saniye_sonraki[5:0] <= saniye_ayari[5:0];
        end    

        // 7 segment display icin basamaklara ayirdik.
        saat_onluk_deger <= (saat / 10);
        saat_birlik_deger <= (saat % 10);
        
        dakika_onluk_deger <= (dakika / 10);
        dakika_birlik_deger <= (dakika % 10);
        
        saniye_onluk_deger <= (led_gosterimi / 10);
        saniye_onluk_deger <= (led_gosterimi % 10);
        
        gun_onluk_deger <= (gun / 10);
        gun_birlik_deger <= (gun % 10);
        
        ay_onluk_deger <= (ay / 10);
        ay_birlik_deger <= (ay % 10);
        
        yil_binlik_deger <= (yil / 1000);
        yil_yuzluk_deger <= ((yil - yil_binlik_deger * 1000) / 100);
        yil_onluk_deger <= ((yil - yil_binlik_deger * 1000 - yil_yuzluk_deger * 100) / 10);
        yil_birlik_deger <= ((yil - yil_binlik_deger * 1000 - yil_yuzluk_deger * 100 - yil_onluk_deger * 10) % 10);
        
        dp <= 1'd1;
        

    end  
    
    seg7_control(.clk_100MHz(CLK),.reset(reset),.hrs_tens(saat_onluk_deger),.hrs_ones(saat_birlik_deger),.mins_tens(dakika_onluk_deger),.mins_ones(dakika_birlik_deger),.seg(seg),.an(an));

    always @(posedge CLK or posedge reset) begin
        if (reset) begin
            led_gosterimi <= 6'd0;
            dakika <= 6'd30;
            saat <= 5'd18;
            gun <= 5'd30;
            ay <= 4'd7;
            yil <= 12'd2024;
            
            calisma_durumu <= 1'd1;    

            sayac <= 30'd0;

            hiz_katsayisi <= 13'd1;
            
        end else begin
            led_gosterimi <= saniye_sonraki;
            dakika <= dakika_sonraki;
            saat <= saat_sonraki;
            gun <= gun_sonraki;
            ay <= ay_sonraki;
            yil <= yil_sonraki;
            
            if (temiz_sinyal_durdur_baslat && ~temiz_sinyal_onceki_durdur_baslat) begin
                calisma_durumu <= ~calisma_durumu; // Sadece pozitif kenarda durum de?i?tir
            end
            temiz_sinyal_onceki_durdur_baslat <= temiz_sinyal_durdur_baslat; // Önceki durumu güncelle
            
            sayac <= sayac_sonraki;
            
            hiz_katsayisi <= hiz_katsayisi_sonraki;
            
             // Temiz sinyal güncellemeleri
            temiz_sinyal_onceki_saat_arttir <= temiz_sinyal_saat_arttir;
            temiz_sinyal_onceki_saat_azalt <= temiz_sinyal_saat_azalt;
            temiz_sinyal_onceki_dakika_arttir <= temiz_sinyal_dakika_arttir;
            temiz_sinyal_onceki_dakika_azalt <= temiz_sinyal_dakika_azalt;
            
            if(uart_rx_valid) begin
                if(uart_rx_data == 8'h54) begin
                    case (sira)
                        5'd0: begin
                            tx_data_reg <= gun_onluk_deger+ 8'd48;  // Gün onluk basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd1;
                        end
                        5'd1: begin
                            tx_data_reg <= gun_birlik_deger + 8'd48;  // Gün birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd2;
                        end
                        5'd2: begin
                            tx_data_reg <= 8'h2E;  // '.' karakteri
                            tx_en_reg <= 1'b1;
                            sira <= 5'd3;
                        end
                        5'd3: begin
                            tx_data_reg <= ay_onluk_deger + 8'd48;  // Ay onluk basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd4;
                        end
                        5'd4: begin
                            tx_data_reg <= ay_birlik_deger + 8'd48;  // Ay birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd5;
                        end
                        5'd5: begin
                            tx_data_reg <= 8'h2E;  // '.' karakteri
                            tx_en_reg <= 1'b1;
                            sira <= 5'd6;
                        end
                        5'd6: begin
                            tx_data_reg <= yil_binlik_deger + 8'd48;  // Yıl binler basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd7;
                        end
                        5'd7: begin
                            tx_data_reg <= yil_yuzluk_deger + 8'd48;  // Yıl yüzler basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd8;
                        end
                        5'd8: begin
                            tx_data_reg <= yil_onluk_deger + 8'd48;  // Yıl onlar basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd9;
                        end
                        5'd9: begin
                            tx_data_reg <= yil_birlik_deger + 8'd48;  // Yıl birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd10;
                        end
                        5'd10: begin
                            tx_data_reg <= 8'd32;  // bosluk karakteri
                            tx_en_reg <= 1'b1;
                            sira <= 5'd11;
                        end
                        5'd11: begin
                            tx_data_reg <= saat_onluk_deger + 8'd48;  // Saat onluk basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd12;
                        end
                        5'd12: begin
                            tx_data_reg <= saat_birlik_deger + 8'd48;  // Saat birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd13;
                        end
                        5'd13: begin
                            tx_data_reg <= 8'd58;  // ':' karakteri
                            tx_en_reg <= 1'b1;
                            sira <= 5'd14;
                        end
                        5'd14: begin
                            tx_data_reg <= dakika_onluk_deger + 8'd48;  // Dakika onluk basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd15;
                        end
                        5'd15: begin
                            tx_data_reg <= dakika_birlik_deger + 8'd48;  // Dakika birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd16;
                        end
                        5'd16: begin
                            tx_data_reg <= 8'd58;  // ':' karakteri
                            tx_en_reg <= 1'b1;
                            sira <= 5'd17;
                        end
                        5'd17: begin
                            tx_data_reg <= saniye_onluk_deger + 8'd48;  // Saniye onluk basamagi
                            tx_en_reg <= 1'b1;
                            sira <= 5'd18;
                        end
                        5'd18: begin
                            tx_data_reg <= saniye_birlik_deger + 8'd48;  // Saniye birlik basamağı
                            tx_en_reg <= 1'b1;
                            sira <= 5'd19;
                        end
                        5'd19: begin
                            tx_en_reg <= 1'b0;  // Gönderim tamamlandı, sinyal kapatılıyor
                            sira <= 5'd0;
                        end
                    endcase
                    
                    
                end
            end
            
        end
    end
    
endmodule