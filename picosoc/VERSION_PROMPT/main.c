#include "firmware.h"
#include "irq_functions.h"
#include "irq.h"
#include "uart.h"
#include <stdbool.h>

// Pour l'IRQ
#define COUNT 100000000

// Les differents peripheriques presents sur le SoC
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_circuit_seed (*(volatile uint32_t*)0x02000018)
#define reg_circuit_data (*(volatile uint32_t*)0x0200000c)
#define reg_leds (*(volatile uint32_t*)0x03000000)

#define reg_circut_perm1 (*(volatile uint32_t*)0x02000010)
#define reg_circut_perm2 (*(volatile uint32_t*)0x02000018)
#define reg_circut_perm3 (*(volatile uint32_t*)0x02000020)
#define reg_circut_perm4 (*(volatile uint32_t*)0x02000028)
#define reg_circut_perm5 (*(volatile uint32_t*)0x02000030)
#define reg_circut_perm6 (*(volatile uint32_t*)0x02000038)
#define reg_circut_perm7 (*(volatile uint32_t*)0x02000040)
#define reg_circut_perm8 (*(volatile uint32_t*)0x02000048)
#define reg_circut_perm9 (*(volatile uint32_t*)0x02000050)
#define reg_circut_perm10 (*(volatile uint32_t*)0x02000058)

int main(void)
{
  _picorv32_setmask(0);
  _picorv32_timer(COUNT);
  print_str("\r\nHello from PicoSoC !\r\n");

  char caractere;
    for(;;)
    {
      reg_leds = 0xff;
      print("Seed123123: ");
      print_hex(reg_circuit_seed,8);
      print("\n");
      // reg_circuit_seed = 0xbabecafe;
      //["0xB1052995B8707739", "0xD6D42CBB78BB010A", "0xF1C1629EC1FF700B", "0xDA64243D428EB536", "0xDB31C36D4DE2971E"]
      reg_circuit_seed = 0x00000010;

      reg_circut_perm1 = 0xb1052995;
      reg_circut_perm2 = 0xb8707739;
      reg_circut_perm3 = 0xd6d42cbb;
      reg_circut_perm4 = 0x78bb010a;
      reg_circut_perm5 = 0xf1c1629e;
      reg_circut_perm6 = 0xc1ff700b;
      reg_circut_perm7 = 0xda64243d;
      reg_circut_perm8 = 0x428eb536;
      reg_circut_perm9 = 0xdb31c36d;
      reg_circut_perm10 = 0x4de2971e;

      print("Seed: ");
      print_hex(reg_circuit_seed,8);
      print("\n");
      print("Perm1: ");
      print_hex(reg_circut_perm1,8);
      print("\n");
      print("Perm2: ");
      print_hex(reg_circut_perm2,8);
      print("\n");
      for (int i = 0; i < 10; i++)
      {
        print("Valeur: ");
        print_hex(reg_circuit_data,8);
        print("\n");
      }
      print("Hello World!\n");
      do{
          caractere = getchar();
          reg_leds = 0;
      }
      while (caractere == 0xFF);
      print(&caractere);
    }

  //  char caractere;
  //   for(;;)
  //   {
  //     reg_leds = 0xff;
  //     print("Seed: ");
  //     print_hex(reg_circuit_seed,8);
  //     print("\n");
  //     reg_circuit_seed = 0xbabecafe;
  //     print("Seed: ");
  //     print_hex(reg_circuit_seed,8);
  //     print("\n");
  //     print("Valeur: ");
  //     print_hex(reg_circuit_data,8);
  //     print("\n");
  //     print("Valeur: ");
  //     print_hex(reg_circuit_data,8);
  //     print("\n");
  //     print("Valeur: ");
  //     print_hex(reg_circuit_data,8);
  //     print("\n");
  //     print("Hello World!\n");
  //     do{
  //         caractere = getchar();
  //         reg_leds = 0;
  //     }
  //     while (caractere == 0xFF);
  //     print(&caractere);
  //   }
  
}
