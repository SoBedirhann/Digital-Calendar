`timescale 1ns / 1ps

module impl_top(
    input CLK, reset, hiz_degisikligi,
    input [4:0] butonlar,
    input [5:0] saniye_ayari,
    input rx,
    output tx,
    output [3:0] an,                // Basamak gösterimi
    output [6:0] seg,               // 7 parçali gösterimin bolumleri
    output dp,                      // Ondalik gösterimin noktasi
    output [5:0] led_gosterimi
);

    // Saat guncelleme modulunu cagir
    saat_guncelleme u_saat_guncelleme (
        .CLK(CLK),
        .reset(reset),
        .butonlar(butonlar),
        .saniye_ayari(saniye_ayari),
        .rx(rx),
        .tx(tx),
        .hiz_degisikligi(hiz_degisikligi),
        .seg(seg),
        .an(an),
        .dp(dp),
        .led_gosterimi(led_gosterimi)
    );

endmodule
