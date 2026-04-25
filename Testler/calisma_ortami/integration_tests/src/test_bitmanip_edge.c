//===========================================================
// HexaChipsers RV32IMAFB — Bit Manipulation Edge Case Test
//-----------------------------------------------------------
// Tests all Zba/Zbb/Zbc/Zbs instructions with boundary
// values. Validates Faz 1 SHAMT fix (EX_ALU_IMM→EX_ALU_SHAMT)
//===========================================================

#include "test_common.h"

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();

    printf("\n<<< HexaChipsers Bit Manipulation Edge Case Test >>>\n\n");

    uint32_t result;
    uint32_t a, b;

    // ==========================================
    //  Zba: Address Generation
    // ==========================================
    printf("--- Zba: SH1ADD, SH2ADD, SH3ADD ---\n");
    {
        a = 0x10; b = 0x100;
        asm volatile("sh1add %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("SH1ADD(0x10,0x100)", result, (a << 1) + b);

        asm volatile("sh2add %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("SH2ADD(0x10,0x100)", result, (a << 2) + b);

        asm volatile("sh3add %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("SH3ADD(0x10,0x100)", result, (a << 3) + b);

        // Boundary: max values
        a = 0xFFFFFFFF; b = 0xFFFFFFFF;
        asm volatile("sh1add %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("SH1ADD(0xFFFF,0xFFFF)", result, (a << 1) + b);

        // Boundary: zero
        a = 0; b = 0;
        asm volatile("sh1add %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("SH1ADD(0,0)", result, 0);
    }

    // ==========================================
    //  Zbb: Basic Bit Manipulation
    // ==========================================
    printf("\n--- Zbb: ANDN, ORN, XNOR ---\n");
    {
        a = 0xFF00FF00; b = 0x0F0F0F0F;
        asm volatile("andn %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("ANDN(0xFF00FF00,0x0F0F0F0F)", result, a & (~b));

        asm volatile("orn %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("ORN(0xFF00FF00,0x0F0F0F0F)", result, a | (~b));

        asm volatile("xnor %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("XNOR(0xFF00FF00,0x0F0F0F0F)", result, ~(a ^ b));
    }

    printf("\n--- Zbb: CLZ, CTZ, CPOP ---\n");
    {
        a = 0x00000001;
        asm volatile("clz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CLZ(0x00000001)", result, 31);

        a = 0x80000000;
        asm volatile("clz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CLZ(0x80000000)", result, 0);

        a = 0x00000000;
        asm volatile("clz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CLZ(0x00000000)", result, 32);

        a = 0xFFFFFFFF;
        asm volatile("clz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CLZ(0xFFFFFFFF)", result, 0);

        // CTZ
        a = 0x80000000;
        asm volatile("ctz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CTZ(0x80000000)", result, 31);

        a = 0x00000001;
        asm volatile("ctz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CTZ(0x00000001)", result, 0);

        a = 0x00000000;
        asm volatile("ctz %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CTZ(0x00000000)", result, 32);

        // CPOP
        a = 0x00000000;
        asm volatile("cpop %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CPOP(0x00000000)", result, 0);

        a = 0xFFFFFFFF;
        asm volatile("cpop %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CPOP(0xFFFFFFFF)", result, 32);

        a = 0xAAAAAAAA;
        asm volatile("cpop %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("CPOP(0xAAAAAAAA)", result, 16);
    }

    printf("\n--- Zbb: MAX, MIN, MAXU, MINU ---\n");
    {
        a = 0x7FFFFFFF; b = 0x80000000; // max_int, min_int
        asm volatile("max %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("MAX(0x7FFF,0x8000) signed", result, 0x7FFFFFFF);

        asm volatile("min %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("MIN(0x7FFF,0x8000) signed", result, 0x80000000);

        asm volatile("maxu %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("MAXU(0x7FFF,0x8000) unsigned", result, 0x80000000);

        asm volatile("minu %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("MINU(0x7FFF,0x8000) unsigned", result, 0x7FFFFFFF);
    }

    printf("\n--- Zbb: SEXT.B, SEXT.H, ZEXT.H ---\n");
    {
        a = 0x000000FF; // -1 as byte
        asm volatile("sext.b %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("SEXT.B(0xFF)", result, 0xFFFFFFFF);

        a = 0x0000007F; // +127 as byte
        asm volatile("sext.b %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("SEXT.B(0x7F)", result, 0x0000007F);

        a = 0x0000FFFF; // -1 as halfword
        asm volatile("sext.h %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("SEXT.H(0xFFFF)", result, 0xFFFFFFFF);

        a = 0x00007FFF; // +32767 as halfword
        asm volatile("sext.h %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("SEXT.H(0x7FFF)", result, 0x00007FFF);

        a = 0xDEADBEEF;
        asm volatile("zext.h %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("ZEXT.H(0xDEADBEEF)", result, 0x0000BEEF);
    }

    printf("\n--- Zbb: ROL, ROR, RORI ---\n");
    {
        a = 0x80000001;
        b = 1;
        asm volatile("rol %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("ROL(0x80000001,1)", result, 0x00000003);

        asm volatile("ror %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("ROR(0x80000001,1)", result, 0xC0000000);

        // RORI with shamt=0 (should be identity) — validates SHAMT fix
        asm volatile("rori %0, %1, 0" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("RORI(0x80000001,0) identity", result, 0x80000001);

        // RORI with shamt=16
        a = 0x12345678;
        asm volatile("rori %0, %1, 16" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("RORI(0x12345678,16)", result, 0x56781234);

        // RORI with shamt=31
        a = 0x00000001;
        asm volatile("rori %0, %1, 31" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("RORI(0x1,31)", result, 0x00000002);
    }

    printf("\n--- Zbb: ORC.B, REV8 ---\n");
    {
        a = 0x00FF0100;
        asm volatile("orc.b %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("ORC.B(0x00FF0100)", result, 0x00FFFFFF);

        a = 0x00000000;
        asm volatile("orc.b %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("ORC.B(0x00000000)", result, 0x00000000);

        a = 0x12345678;
        asm volatile("rev8 %0, %1" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("REV8(0x12345678)", result, 0x78563412);
    }

    // ==========================================
    //  Zbc: Carry-less Multiply
    // ==========================================
    printf("\n--- Zbc: CLMUL, CLMULH, CLMULR ---\n");
    {
        a = 0x00000003; b = 0x00000005;
        asm volatile("clmul %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        // clmul(3,5) = clmul(0b11, 0b101) = 0b11 ^ 0b1100 ^ 0 = 0b1111 = 0xF
        TEST_CHECK_EQ("CLMUL(0x3,0x5)", result, 0x0000000F);

        a = 0x00000000;
        asm volatile("clmul %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("CLMUL(0,0x5)", result, 0);
    }

    // ==========================================
    //  Zbs: Single-Bit Instructions
    //  ** KEY: validates EX_ALU_SHAMT fix **
    // ==========================================
    printf("\n--- Zbs: BCLR, BCLRI, BEXT, BEXTI, BINV, BINVI, BSET, BSETI ---\n");
    {
        // BCLR: clear bit rs2[4:0] of rs1
        a = 0xFFFFFFFF; b = 0;
        asm volatile("bclr %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BCLR(0xFFFF,bit0)", result, 0xFFFFFFFE);

        a = 0xFFFFFFFF; b = 31;
        asm volatile("bclr %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BCLR(0xFFFF,bit31)", result, 0x7FFFFFFF);

        // BCLRI — immediate version (SHAMT fix validation!)
        a = 0xFFFFFFFF;
        asm volatile("bclri %0, %1, 5" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BCLRI(0xFFFF,5)", result, 0xFFFFFFDF);

        asm volatile("bclri %0, %1, 0" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BCLRI(0xFFFF,0)", result, 0xFFFFFFFE);

        asm volatile("bclri %0, %1, 31" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BCLRI(0xFFFF,31)", result, 0x7FFFFFFF);

        // BEXT: extract bit rs2[4:0] of rs1
        a = 0x00000020; // bit 5 set
        b = 5;
        asm volatile("bext %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BEXT(0x20,bit5)", result, 1);

        b = 4;
        asm volatile("bext %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BEXT(0x20,bit4)", result, 0);

        // BEXTI
        a = 0x80000000;
        asm volatile("bexti %0, %1, 31" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BEXTI(0x8000,31)", result, 1);

        asm volatile("bexti %0, %1, 0" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BEXTI(0x8000,0)", result, 0);

        // BINV: invert bit
        a = 0x00000000;
        b = 5;
        asm volatile("binv %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BINV(0x0,bit5)", result, 0x00000020);

        // BINVI (SHAMT fix validation!)
        a = 0x00000000;
        asm volatile("binvi %0, %1, 5" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BINVI(0x0,5)", result, 0x00000020);

        asm volatile("binvi %0, %1, 0" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BINVI(0x0,0)", result, 0x00000001);

        asm volatile("binvi %0, %1, 31" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BINVI(0x0,31)", result, 0x80000000);

        // BSET: set bit
        a = 0x00000000;
        b = 7;
        asm volatile("bset %0, %1, %2" : "=r"(result) : "r"(a), "r"(b));
        TEST_CHECK_EQ("BSET(0x0,bit7)", result, 0x00000080);

        // BSETI (SHAMT fix validation!)
        a = 0x00000000;
        asm volatile("bseti %0, %1, 5" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BSETI(0x0,5)", result, 0x00000020);

        asm volatile("bseti %0, %1, 0" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BSETI(0x0,0)", result, 0x00000001);

        asm volatile("bseti %0, %1, 31" : "=r"(result) : "r"(a));
        TEST_CHECK_EQ("BSETI(0x0,31)", result, 0x80000000);
    }

    TEST_SUMMARY("BIT MANIPULATION EDGE CASE");
}

//===========================================================
// End of Program
//===========================================================
