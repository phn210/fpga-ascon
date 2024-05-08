#include "irq_functions.h"
#include <stdint.h>

void __attribute__((naked)) _picorv32_setmask(uint32_t to)
{
    picorv32_maskirq_insn(a0, a0);
    asm __volatile__ ("ret\n"); 
}

void __attribute__((naked)) _picorv32_timer(uint32_t to)
{
    picorv32_timer_insn(a0, a0);
    asm __volatile__ ("ret\n"); 
}

uint32_t *__attribute__((naked)) _picorv32_waitirq(void)
{
  picorv32_waitirq_insn(a0);
  asm __volatile__ ("ret\n");
}
