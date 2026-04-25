#include "libs/sys/timer/timer.h"
#include "libs/util/delay.h"
#include "libs/sys/gpio/gpio.h"
#include "libs/sys/serial/serial.h"
#include "libs/util/print.h"
#include "libs/lcd/LCD.h"
#include "libs/dht11/dht.h"
#include <stdlib.h>
#include <math.h>  


extern __attribute__((section (".reset"), naked))

void _reset(){

    // stack temizleme

    __asm(".option push\n"
          ".option norelax\n"
          "la gp, __global_pointer$\n"
          ".option pop");
    __asm("la sp, __stack_top");
    __asm("add s0, sp, zero");

}

//leibniz serisini kullanarak pi sayısını hesaplayan örnek algoritma pi=4(1-1/3+1/5-1/7+1/9...)

int main() {

    printf(".:|>HexaChipsters<|:.\n");
    printf("Pi sayisi hesaplama algoritmasi\n");
    printf("2024\n");
  
    float pi = 0;
    int n = 1000; // Hesaplanacak terim sayısı
    int sign = 1; // İşaret değişkeni

    for (int i = 0; i < n; i++) {
        pi += sign * (4.0f / (2 * i + 1));
        sign = -sign; // İşareti değiştir
        // Tam ve ondalık basamakları yazdırma
        int tamKisim = (int)pi; // Tam kısmı al
        float ondalikKisim = pi - tamKisim; // Ondalık kısmı hesapla
        printf("iterasyon sayisi= %d: Pi = %d.%05d\n", i + 1, tamKisim, (int)(ondalikKisim * 100000)); // Ondalık kısmı 3 basamak hassasiyetle yazdır
    }

    // Sonuç olarak hesaplanan Pi değeri
    // Tam ve ondalık basamakları yazdırma

    int tamKisim = (int)pi; // Tam kısmı al
    float ondalikKisim = pi - tamKisim; // Ondalık kısmı hesapla
    printf("Final Pi sayisi==> %d.%05d\n", tamKisim, (int)(ondalikKisim * 100000)); // Ondalık kısmı 3 basamak hassasiyetle yazdır
    printf("Son... \n");
    delay_ms(500);

    return 0;
}
