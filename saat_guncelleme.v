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
    output [3:0] an,    // Aktif 7-segment basamagi
    output hsync, vsync,
    output [2:0] rgb
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

    reg [6:0] hiz_katsayisi = 7'd1, hiz_katsayisi_sonraki; 

    localparam BIR_SANIYE = 100000000;
    
    // basamaklarina ayirma islemi
    reg[3:0] deger = 4'd0, deger_sonraki;
    reg [3:0] saat_birlik_deger , dakika_birlik_deger, gun_birlik_deger, saniye_onluk_deger, saniye_birlik_deger;
    reg [3:0] yil_binlik_deger, yil_yuzluk_deger, yil_onluk_deger, yil_birlik_deger, ay_birlik_deger;
    reg [2:0] saat_onluk_deger, dakika_onluk_deger, gun_onluk_deger;
    reg ay_onluk_deger;
    
    
    //VGA MEVZUSU
    wire clk_148_5MHz;           // PLL/MMCM taraf?ndan olu?turulan 148.5 MHz'lik saat sinyali
    wire [31:0] pixel_x;          // Yatay piksel pozisyonu
    wire [31:0] pixel_y;          // Dikey piksel pozisyonu
    wire video_on;               // Video etkin sinyali
    
     // Clocking Wizard modülü (Vivado'da otomatik olu?turulacak)
    clk_wiz_0 clk_wizard (
        .clk_out1(clk_148_5MHz), // 148.5 MHz ç?k??
        .clk_in1(CLK),    // 100 MHz giri?
        .reset(reset)
    );  
    
    
    // VGA senkronizasyon modülü
    vga_sync sync(
        .clk_148_5MHz(clk_148_5MHz), // 148.5 MHz saat sinyali
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on)
    );

    // VGA görüntüleme modülü
    vga_display vga_display_inst (
        .clk_148_5MHz(clk_148_5MHz), // 148.5 MHz saat sinyali
        .reset(reset),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .yil_binlik(yil_binlik_deger), // Y?l?n binlik basama??
        .yil_yuzluk(yil_yuzluk_deger), // Y?l?n yüzlük basama??
        .yil_onluk(yil_onluk_deger),   // Y?l?n onluk basama??
        .yil_birlik(yil_birlik_deger), // Y?l?n birlik basama??
        .ay_onluk(ay_onluk_deger),       // Ay?n onluk basama??
        .ay_birlik(ay_birlik_deger),     // Ay?n birlik basama??
        .gun_onluk(gun_onluk_deger),      // Günün onluk basama??
        .gun_birlik(gun_birlik_deger),    // Günün birlik basama??
        .saat_onluk(saat_onluk_deger),     // Saatin onluk basama??
        .saat_birlik(saat_birlik_deger),   // Saatin birlik basama??
        .dakika_onluk(dakika_onluk_deger), // Dakikan?n onluk basama??
        .dakika_birlik(dakika_birlik_deger),// Dakikan?n birlik basama??
        .saniye_onluk(saniye_onluk_deger), // Saniyenin onluk basama??
        .saniye_birlik(saniye_birlik_deger),// Saniyenin birlik basama??
        .rgb(rgb),
        .video_on(video_on)
    );
    
    
    
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
    

    
    wire [7:0] uart_rx_data;
    wire uart_rx_valid;
    wire uart_rx_break;
    
    wire uart_tx_busy;
    reg [7:0] uart_tx_data;
    reg uart_tx_en;
    
    reg [7:0] tx_data_reg;
    reg tx_en_reg;
    reg tx_start;
    reg tx_T_start = 1'b0, rx_G_start = 1'b0;
    reg[13:0] gelen_veri;
    reg[4:0] sira_T = 5'd0;
    reg[3:0] sira_G = 4'd0;
    reg [3:0] veri_sayac = 4'd0;
    reg veri_yukle = 1'b0;
    reg T_basildi = 1'b0;
    uart_rx i_uart_rx(
    .clk(CLK), // Top level system clock input.
    .reset (reset), // Asynchronous active low reset.
    .rx (rx), // UART Recieve pin.
    .rx_ready (uart_rx_valid), // Valid data recieved and available.
    .rx_data (uart_rx_data)  // The recieved data.
    );
    
    //
    // UART Transmitter module.
    //
    uart_tx _uart_tx(
    .clk (CLK),
    .reset (reset),
    .tx (tx),
    .en(uart_tx_en),
    .tx_start(tx_start),
    .tx_busy (uart_tx_busy),
    .tx_data (uart_tx_data) 
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
        

        
        if(hiz_degisikligi) begin
            if(hiz_katsayisi < 128) begin
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
        saniye_birlik_deger <= (led_gosterimi % 10);
        
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
    
    seg7_control uut(.clk_100MHz(CLK),.reset(reset),.hrs_tens(saat_onluk_deger),.hrs_ones(saat_birlik_deger),.mins_tens(dakika_onluk_deger),.mins_ones(dakika_birlik_deger),.seg(seg),.an(an));

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
            tx_T_start <= 1'b0;
            rx_G_start <= 1'b0;
            sira_T <= 5'd0;
            sira_G <= 4'd0;
            veri_sayac <= 4'd0;
            uart_tx_en <= 1'b0;
            veri_yukle <= 1'b0;
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
            
            // T TUSUNA BASILIP ENTER BASILDIGINDA TARIH SAAT BASILIR.
            if(uart_rx_valid && uart_rx_data == 8'h54) begin
                T_basildi <= 1'b1;
            end
            if(T_basildi && uart_rx_data == 8'd13 && uart_rx_valid) begin
                tx_T_start <= 1'b1;
                tx_start <= 1'b1;
                uart_tx_en <= 1'b1;
            end
            if(tx_T_start && !uart_tx_busy) begin
                case (sira_T)
                    5'd0: begin
                        uart_tx_data <= gun_onluk_deger + 8'd48;  // Gün onluk basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd1;
                    end
                    5'd1: begin
                        uart_tx_data <= gun_birlik_deger + 8'd48;  // Gün birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd2;
                    end
                    5'd2: begin
                        uart_tx_data <= 8'h2E;  // '.' karakteri
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd3;
                    end
                    5'd3: begin
                        uart_tx_data <= ay_onluk_deger + 8'd48;  // Ay onluk basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd4;
                    end
                    5'd4: begin
                        uart_tx_data <= ay_birlik_deger + 8'd48;  // Ay birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd5;
                    end
                    5'd5: begin
                        uart_tx_data <= 8'h2E;  // '.' karakteri
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd6;
                    end
                    5'd6: begin
                        uart_tx_data <= yil_binlik_deger + 8'd48;  // Y?l binler basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd7;
                    end
                    5'd7: begin
                        uart_tx_data <= yil_yuzluk_deger + 8'd48;  // Y?l yüzler basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd8;
                    end
                    5'd8: begin
                        uart_tx_data <= yil_onluk_deger + 8'd48;  // Y?l onlar basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd9;
                    end
                    5'd9: begin
                        uart_tx_data <= yil_birlik_deger + 8'd48;  // Y?l birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd10;
                    end
                    5'd10: begin
                        uart_tx_data <= 8'd32;  // bosluk karakteri
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd11;
                    end
                    5'd11: begin
                        uart_tx_data <= saat_onluk_deger + 8'd48;  // Saat onluk basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd12;
                    end
                    5'd12: begin
                        uart_tx_data <= saat_birlik_deger + 8'd48;  // Saat birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd13;
                    end
                    5'd13: begin
                        uart_tx_data <= 8'd58;  // ':' karakteri
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd14;
                    end
                    5'd14: begin
                        uart_tx_data <= dakika_onluk_deger + 8'd48;  // Dakika onluk basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd15;
                    end
                    5'd15: begin
                        uart_tx_data <= dakika_birlik_deger + 8'd48;  // Dakika birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd16;
                    end
                    5'd16: begin
                        uart_tx_data <= 8'd58;  // ':' karakteri
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd17;
                    end
                    5'd17: begin
                        uart_tx_data <= saniye_onluk_deger + 8'd48;  // Saniye onluk basamagi
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd18;
                    end
                    5'd18: begin
                        uart_tx_data <= saniye_birlik_deger + 8'd48;  // Saniye birlik basama??
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd19;
                    end
                    5'd19: begin
                        uart_tx_data <= 8'd32;
                        uart_tx_en <= 1'b1;
                        sira_T <= 5'd20;
                    end
                    5'd20: begin
                        uart_tx_en <= 1'b0;  // Gönderim tamamland?, sinyal kapat?l?yor
                        sira_T <= 5'd0;
                        tx_T_start <= 1'b0;
                        tx_start <= 1'b0;
                        T_basildi <= 1'b0;
                    end                    
                endcase
            end
            
        //      G TUSUNA BASILDIKTAN SONRA GELEN INPUT ILE TARIH AYARLANIR.
        if(uart_rx_valid && uart_rx_data == 8'h47) begin
                  rx_G_start = 1'b1;
        end   
        if(rx_G_start && uart_rx_valid && !(uart_rx_data == 8'h47)) begin
            case (veri_sayac) 
            4'd0: begin
                gelen_veri[0] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd1: begin
                gelen_veri[1] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd2: begin
                gelen_veri[2] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd3: begin
                gelen_veri[3] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd4: begin
                gelen_veri[4] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd5: begin
                gelen_veri[5] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd6: begin
                gelen_veri[6] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd7: begin
                gelen_veri[7] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd8: begin
                gelen_veri[8] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd9: begin
                gelen_veri[9] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd10: begin
                gelen_veri[10] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd11: begin
                gelen_veri[11] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd12: begin
                gelen_veri[12] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd13: begin
                gelen_veri[13] <= uart_rx_data - 8'd48;
                veri_sayac <= veri_sayac + 1;
            end
            4'd14: begin
                veri_sayac <= 4'd0;
                rx_G_start <= 1'd0;
                veri_yukle <= 1'b1;
            end
        endcase 
        end   
        if(veri_yukle) begin
            gun <= gelen_veri[0] * 10 + gelen_veri[1];
                               
            ay <= gelen_veri[2] * 10 + gelen_veri[3];
                               
            yil <= gelen_veri[4] * 1000 + gelen_veri[5] * 100 + gelen_veri[6] * 10 + gelen_veri[7];
                               
            saat <= gelen_veri[8] * 10 + gelen_veri[9];
                               
            dakika <= gelen_veri[10] * 10 + gelen_veri[11];
            
            led_gosterimi <= gelen_veri[12] *  10 + gelen_veri[13];
              
            veri_yukle <= 1'b0;
        end
        end
    end
    
  
endmodule