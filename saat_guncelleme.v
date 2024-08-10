`timescale 1ns / 1ps

module saat_guncelleme(
    input CLK, reset, hiz_degisikligi,
    input [4:0] butonlar,
    input rx,
    output tx,
    output reg [5:0] led_gosterimi,
    output [0:6] seg,  // 7-segment display icin segment cikislari
    output reg dp,         // Ondalik nokta cikisi
    output [3:0] an    // Aktif 7-segment basamagi
);
    
    // baslangic degerleri
    reg [5:0] saniye = 6'd0, saniye_sonraki;
    reg [5:0] dakika = 6'd30, dakika_sonraki;
    reg [4:0] saat = 5'd18, saat_sonraki;
    reg [4:0] gun = 5'd30, gun_sonraki;
    reg [3:0] ay = 4'd7, ay_sonraki;
    reg [11:0] yil = 12'd2024, yil_sonraki;
    

    reg calisma_durumu = 1'd1; 

    reg [29:0] sayac = 30'd0, sayac_sonraki;

    reg [12:0] hiz_katsayisi = 13'd1, hiz_katsayisi_sonraki; 

    localparam BIR_SANIYE = 100000000;
    
    reg[3:0] deger = 4'd0, deger_sonraki;
    reg [3:0] saat_birlik_deger , dakika_birlik_deger;
    reg [2:0] saat_onluk_deger, dakika_onluk_deger;
    // UART RX için sinyaller
    wire [7:0] uart_rx_data;
    wire uart_rx_valid;
    wire uart_rx_break;
    
    // UART RX modülünün baslatilmasi
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
    
    uart_tx #(
        .BIT_RATE(9600),
        .CLK_HZ(100_000_000),
        .PAYLOAD_BITS(8)
    ) uart_transmitter (
        .CLK(CLK),
        .reset(reset),
        .uart_tx_en(uart_tx_en),
        .uart_tx_data(uart_tx_data),
        .uart_txd(tx),
        .uart_tx_busy(uart_tx_busy)
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
    
    always @* begin
        // Varsayilan atamalar
        saniye_sonraki = saniye;
        led_gosterimi = saniye;
        dakika_sonraki = dakika;
        saat_sonraki = saat;
        gun_sonraki = gun;
        ay_sonraki = ay;
        yil_sonraki = yil;
        sayac_sonraki = sayac + 1;

        hiz_katsayisi_sonraki = hiz_katsayisi;
     
         //                                                      UART Komutlari
//    if (uart_rx_valid) begin
//        // 'T' komutunu algila ve mevcut tarihi yazdir
//        if (uart_rx_data == 8'h54) begin // ASCII 'T'
//            uart_tx_en = 1'b1;
//            uart_tx_data = "Tarih ve Saat: "; // Ornek baslik

//            // Tarihi ve saati yazdir
//            // Her bir degeri ASCII olarak gonder
//            uart_tx_data = 8'h30 + (gun / 10); // gun'un onluk basamagini gonder
//            uart_tx_data = 8'h30 + (gun % 10); // gun'un birlik basamagini gonder
//            uart_tx_data = ".";

//            uart_tx_data = 8'h30 + (ay / 10);  // ay'in onluk basamagini gonder
//            uart_tx_data = 8'h30 + (ay % 10);  // ay'in birlik basamagini gonder
//            uart_tx_data = ".";

//            uart_tx_data = 8'h30 + ((yil / 1000) % 10); // yil'in binlik basamagini gonder
//            uart_tx_data = 8'h30 + ((yil / 100) % 10);  // yil'in yuzluk basamagini gonder
//            uart_tx_data = 8'h30 + ((yil / 10) % 10);   // yil'in onluk basamagini gonder
//            uart_tx_data = 8'h30 + (yil % 10);          // yil'in birlik basamagini gonder
//            uart_tx_data = " ";

//            uart_tx_data = 8'h30 + (saat / 10);  // saat'in onluk basamagini gonder
//            uart_tx_data = 8'h30 + (saat % 10);  // saat'in birlik basamagini gonder
//            uart_tx_data = ":";

//            uart_tx_data = 8'h30 + (dakika / 10); // dakika'nin onluk basamagini gonder
//            uart_tx_data = 8'h30 + (dakika % 10); // dakika'nin birlik basamagini gonder
//            uart_tx_data = ":";

//            uart_tx_data = 8'h30 + (saniye / 10); // saniye'nin onluk basamagini gonder
//            uart_tx_data = 8'h30 + (saniye % 10); // saniye'nin birlik basamagini gonder

//            uart_tx_en = 1'b0; // Gonderimi durdur
//        end

//        // 'G' komutunu algila ve yeni tarihi ayarla
//        if (uart_rx_data == 8'h47) begin // ASCII 'G'
//            uart_tx_en = 1'b0;
//            // G komutundan sonra gelen veriyi ayr??t?r ve tarihi güncelle
//            gun_sonraki = (uart_rx_data[7:4] * 10) + uart_rx_data[3:0]; // Gün
//            ay_sonraki = (uart_rx_data[7:4] * 10) + uart_rx_data[3:0];  // Ay
//            yil_sonraki = (uart_rx_data[7:4] * 1000) + (uart_rx_data[3:0] * 100) + (uart_rx_data[7:4] * 10) + uart_rx_data[3:0]; // Yil
//            saat_sonraki = (uart_rx_data[7:4] * 10) + uart_rx_data[3:0]; // Saat
//            dakika_sonraki = (uart_rx_data[7:4] * 10) + uart_rx_data[3:0]; // Dakika
//            saniye_sonraki = (uart_rx_data[7:4] * 10) + uart_rx_data[3:0]; // Saniye
//        end
//    end
        

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
                saniye_sonraki = saniye + 1;
                if (saniye == 59) begin 
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
        end

        // 7 segment display icin basamaklara ayirdik.
        saat_onluk_deger <= (saat / 10);
        saat_birlik_deger <= (saat % 10);
        dakika_onluk_deger <= (dakika / 10);
        dakika_birlik_deger <= (dakika % 10);
        dp <= 1'd1;
    end  
    
    seg7_control(.clk_100MHz(CLK),.reset(reset),.hrs_tens(saat_onluk_deger),.hrs_ones(saat_birlik_deger),.mins_tens(dakika_onluk_deger),.mins_ones(dakika_birlik_deger),.seg(seg),.an(an));

    always @(posedge CLK or posedge reset) begin
        if (reset) begin
            saniye <= 6'd0;
            dakika <= 6'd30;
            saat <= 5'd18;
            gun <= 5'd30;
            ay <= 4'd7;
            yil <= 12'd2024;
            
            calisma_durumu <= 1'd1;    

            sayac <= 30'd0;

            hiz_katsayisi <= 13'd1;

        end else begin
            saniye <= saniye_sonraki;
            dakika <= dakika_sonraki;
            saat <= saat_sonraki;
            gun <= gun_sonraki;
            ay <= ay_sonraki;
            yil <= yil_sonraki;
            
            if (temiz_sinyal_durdur_baslat && ~temiz_sinyal_onceki_durdur_baslat) begin
                calisma_durumu <= ~calisma_durumu; // Sadece pozitif kenarda durum değiştir
            end
            temiz_sinyal_onceki_durdur_baslat <= temiz_sinyal_durdur_baslat; // Önceki durumu güncelle
            
            sayac <= sayac_sonraki;
            
            hiz_katsayisi <= hiz_katsayisi_sonraki;
            
             // Temiz sinyal güncellemeleri
            temiz_sinyal_onceki_saat_arttir <= temiz_sinyal_saat_arttir;
            temiz_sinyal_onceki_saat_azalt <= temiz_sinyal_saat_azalt;
            temiz_sinyal_onceki_dakika_arttir <= temiz_sinyal_dakika_arttir;
            temiz_sinyal_onceki_dakika_azalt <= temiz_sinyal_dakika_azalt;
        end
    end
    
endmodule