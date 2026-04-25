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

    // stacki temizler


    __asm(".option push\n"
          ".option norelax\n"
          "la gp, __global_pointer$\n"
          ".option pop");
    __asm("la sp, __stack_top");
    __asm("add s0, sp, zero");
}


//leibniz serisini kullanarak pi sayısını hesaplayan örnek algoritma pi=4(1-1/3+1/7-1/7+1/9...)

int main() {

    printf(".:|>HexaChipsters<|:.\n");
    printf("Seri portta okuma ve yazma testi\n");
    printf("2024\n");

    while(1){
          char data_receive[6]={'y','a','z','i','n','.'};
          printf("5 karakterlik bir Metin %s=>\n",data_receive);
          serial_getstr(data_receive, 6);
          printf("Girilen Metin=>%s\n",data_receive);
          printf("Metindeki harfler=>\n");
          for (int i = 0; i < 6; i++) {
             printf("%d. harf=> %c \n",i, data_receive[i]);
          }
          printf("Tek karakter yazin=>\n");
          char karakter=serial_getc();
          printf("Girilen karakter=>%c\n",karakter);
          delay_ms(1000);                  
    }
}
