`timescale 1ns / 1ps

module impl_top(
    input CLK, reset, hiz_degisikligi,
    input [4:0] butonlar,
    input rx,
    output tx,
    output [3:0] an,                // Basamak gösterimi
    output [6:0] seg,               // 7 parçal? gösterimin bölümleri
    output dp,                      // Ondal?k gösterimin noktas?
    output [5:0] led_gosterimi
);

    // Saat güncelleme modülünü ça??r
    saat_guncelleme u_saat_guncelleme (
        .CLK(CLK),
        .reset(reset),
        .butonlar(butonlar),
        .rx(rx),
        .tx(tx),
        .hiz_degisikligi(hiz_degisikligi),
        .seg(seg),
        .an(an),
        .dp(dp),
        .led_gosterimi(led_gosterimi)
    );

endmodule
