#include <stdint.h>

//"q" registers
enum { regnum_q0=0, regnum_q1, regnum_q2, regnum_q3 };

// numbered registers
enum { regnum_x0=0, regnum_x1, regnum_x2, regnum_x3, regnum_x4, regnum_x5, regnum_x6, regnum_x7,
      regnum_x8, regnum_x9, regnum_x10, regnum_x11, regnum_x12, regnum_x13, regnum_x14, regnum_x15,
      regnum_x16, regnum_x17, regnum_x18, regnum_x19, regnum_x20, regnum_x21, regnum_x22, regnum_x23,
      regnum_x24, regnum_x25, regnum_x26, regnum_x27, regnum_x28, regnum_x29, regnum_x30, regnum_x31 };

// registers by usage
enum { regnum_zero=0, regnum_ra, regnum_sp, regnum_gp, regnum_tp, regnum_t0, regnum_t1, regnum_t2,
      regnum_fp=8, regnum_s0=8, regnum_s1, regnum_a0, regnum_a1, regnum_a2, regnum_a3, regnum_a4, regnum_a5,
      regnum_a6, regnum_a7, regnum_s2, regnum_s3, regnum_s4, regnum_s5, regnum_s6, regnum_s7,
      regnum_s8, regnum_s9, regnum_s10, regnum_s11, regnum_t3, regnum_t4, regnum_t5, regnum_t6 };

// emits for picorv32 specific instructions
#define r_type_insn2(_wv) \
    asm __volatile__ (".word %0\n" : : "i" (_wv))

#define r_type_insn(_f7, _rs2, _rs1, _f3, _rd, _opc) \
    r_type_insn2(((_f7) << 25) | ((_rs2) << 20) | ((_rs1) << 15) | ((_f3) << 12) | ((_rd) << 7) | ((_opc) << 0))

#define picorv32_getq_insn(_rd, _qs) \
    r_type_insn(0b0000000, 0, regnum_ ## _qs, 0b100, regnum_ ## _rd, 0b0001011)

#define picorv32_setq_insn(_qd, _rs) \
    r_type_insn(0b0000001, 0, regnum_ ## _rs, 0b010, regnum_ ## _qd, 0b0001011)

#define picorv32_retirq_insn() \
    r_type_insn(0b0000010, 0, 0, 0b000, 0, 0b0001011)

#define picorv32_maskirq_insn(_rd, _rs) \
    r_type_insn(0b0000011, 0, regnum_ ## _rs, 0b110, regnum_ ## _rd, 0b0001011) // mask: 1=disabled

#define picorv32_waitirq_insn(_rd) \
    r_type_insn(0b0000100, 0, 0, 0b100, regnum_ ## _rd, 0b0001011) //wait until an interrupt is pending

#define picorv32_timer_insn(_rd, _rs) \
    r_type_insn(0b0000101, 0, regnum_ ## _rs, 0b110, regnum_ ## _rd, 0b0001011) // if enabled in picorv32, set timer periodicity

void __attribute__((naked)) _picorv32_setmask(uint32_t to);
void __attribute__((naked)) _picorv32_timer(uint32_t to);
uint32_t * __attribute__((naked)) _picorv32_waitirq(void);

