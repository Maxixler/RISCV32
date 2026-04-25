//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Routine
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "csr.h"
#include "float.h"
#include "gpio.h"
#include "interrupt.h"
#include "uart.h"
#include "xprintf.h"

#include "gsensor.h"
#include "i2c.h"
#include "system.h"

#define SXMIN 200 // screen xmin
#define SYMIN 120 // screen ymin
#define SXWID 120 // screen xwidth
#define SYWID 120 // screen ywidth
#define SXMAX (SXMIN+SXWID) // screen xmax
#define SYMAX (SYMIN+SYWID) // screen ymax
#define BALLSIZE  6
#define WALLWIDTH 2
#define XMIN (SXMIN + WALLWIDTH)
#define XMAX ((SXMAX) - (WALLWIDTH) - (BALLSIZE))
#define YMIN (SYMIN + WALLWIDTH)
#define YMAX ((SYMAX) - (WALLWIDTH) - (BALLSIZE))
#define REFLEX(v) (-0.75 * v) // -75%


//-----------------
// Main Routine
//-----------------
void main(void)
{
    int    i;
    double fth, fsin;
    int    ith, isin;
    char   buf[256];
    char   *pbuf;
    long   num;
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    GSENSOR_Init();//
    INT_Init();


 //   printf("<====== HexaChipsters =====>\n");
 //   printf("====== Sinus Fonksiyonu =====\n");
 //   printf("====== Demosu 2024 =====\n");


    printf("<====== HexaChipsters =====>\n");
    printf("====== Gyro_sensor_testi =====\n");
    printf("====== Demosu_2024 =====\n");

/*
    uint32_t a = 0x11;        uint32_t b = 0x85;
            uint32_t imm = 5;        uint32_t result;
            // andn
            asm volatile ("andn %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("andn(%d, %d) = %d\n", a, b, result);
            // bclr
            asm volatile ("bclr %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("bclr(%d, %d) = %d\n", a, b, result);
            // bext
            asm volatile ("bext %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("bext(%d, %d) = %d\n", a, b, result);
            // binv
            asm volatile ("binv %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("binv(%d, %d) = %d\n", a, b, result);
            // bset
            asm volatile ("bset %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("bset(%d, %d) = %d\n", a, b, result);
            // clmul
            asm volatile ("clmul %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("clmul(%d, %d) = %d\n", a, b, result);
            // clmulh
            asm volatile ("clmulh %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("clmulh(%d, %d) = %d\n", a, b, result);
            // clmulr
            asm volatile ("clmulr %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("clmulr(%d, %d) = %d\n", a, b, result);
            // clz
            asm volatile ("clz %0, %1" : "=r" (result) : "r" (a));        printf("clz(%d) = %d\n", a, result);
            // cpop
            asm volatile ("cpop %0, %1" : "=r" (result) : "r" (a));        printf("cpop(%d) = %d\n", a, result);
            // ctz
            asm volatile ("ctz %0, %1" : "=r" (result) : "r" (a));        printf("ctz(%d) = %d\n", a, result);
            // orc.b
            asm volatile ("orc.b %0, %1" : "=r" (result) : "r" (a));        printf("orc.b(%d) = %d\n", a, result);
            // rev8
            asm volatile ("rev8 %0, %1" : "=r" (result) : "r" (a));        printf("rev8(%d) = %d\n", a, result);
            // rol
            asm volatile ("rol %0, %1, %2" : "=r" (result) : "r" (a), "r" (imm));        printf("rol(%d, %d) = %d\n", a, imm, result);
            // ror
            asm volatile ("ror %0, %1, %2" : "=r" (result) : "r" (a), "r" (imm));        printf("ror(%d, %d) = %d\n", a, imm, result);
            // sext.b
            asm volatile ("sext.b %0, %1" : "=r" (result) : "r" (a));        printf("sext.b(%d) = %d\n", a, result);
            // sext.h
            asm volatile ("sext.h %0, %1" : "=r" (result) : "r" (a));        printf("sext.h(%d) = %d\n", a, result);
            // sh1add
            asm volatile ("sh1add %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("sh1add(%d, %d) = %d\n", a, b, result);
            // sh2add
            asm volatile ("sh2add %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("sh2add(%d, %d) = %d\n", a, b, result);
            // sh3add
            asm volatile ("sh3add %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("sh3add(%d, %d) = %d\n", a, b, result);
            // xnor
            asm volatile ("xnor %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));        printf("xnor(%d, %d) = %d\n", a, b, result);
            // zext.h
            asm volatile ("zext.h %0, %1" : "=r" (result) : "r" (a));        printf("zext.h(%d) = %d\n", a, result);
*/


    uint64_t cyclel, cycleh;
    int16_t gX, gY, gZ;
    while(1)
    {
        cyclel = (uint64_t) read_csr(mcycle);
        cycleh = (uint64_t) read_csr(mcycleh);
        //
        GSENSOR_ReadXYZ(&gX, &gY, &gZ);
        //
        printf("Gyro_Verisi = 0x%08x%08x  (gX,gY,gZ)=(%4d,%4d,%4d)\n",
               (int)cycleh, (int)cyclel, (int)gX, (int)gY, (int)gZ);
        //
        //uint32_t seg;
        //seg = (uart_rxd_data << 16) + (i & 0x0ffff);
        GPIO_SetSEG_SignedDecimal((int)gX);
        //
        mem_wr32(0xfffffffc, 0xdeaddead); // Simulation Stop
        //

        //
        printf("<====== HexaChipsters =====>\n");
        Wait_mSec(100);
    }


    //
    // Main Floating
    write_csr(0xbe0, 0x000000ff);
    //main_floating();



}

//===========================================================
// End of Program
//===========================================================
