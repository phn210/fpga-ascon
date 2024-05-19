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
#define reg_encryption_input (*(volatile uint32_t*)0x0200000c)
#define reg_encryption_start (*(volatile uint32_t*)0x02000010)
#define reg_encryption_ready (*(volatile uint32_t*)0x02000014)
#define reg_encryption_output (*(volatile uint32_t*)0x02000018)
#define reg_leds (*(volatile uint32_t*)0x03000000)

int main(void)
{
  _picorv32_setmask(0);
  _picorv32_timer(COUNT);
  print_str("\r\nHello from PicoSoC !\r\n");

  char caractere;
    for(;;)
    {
      reg_leds = 0xff;

      reg_encryption_input = 0x6d653162;
      reg_encryption_input = 0x31743261;
      reg_encryption_input = 0x00003362;
      reg_encryption_input = 0x00003465;
      reg_encryption_input = 0x00003563;
      reg_encryption_input = 0x00003661;
      reg_encryption_input = 0x00003766;
      reg_encryption_input = 0x00003865;
      reg_encryption_input = 0x00003162;
      reg_encryption_input = 0x00003261;
      reg_encryption_input = 0x00003362;
      reg_encryption_input = 0x00003465;
      reg_encryption_input = 0x00003563;
      reg_encryption_input = 0x00003661;
      reg_encryption_input = 0x00003766;
      reg_encryption_input = 0x00003865;

      reg_encryption_start = 1;
      while(reg_encryption_ready == 0) {
        print("Waiting for encryption to finish\n");
      };
      
      print("Emcryption finished\n");
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
