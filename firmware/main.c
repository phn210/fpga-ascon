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
#define reg_encryption_plaintext (*(volatile uint32_t*)0x0200001c)
#define reg_leds (*(volatile uint32_t*)0x03000000)

int main(void)
{
  _picorv32_setmask(0);
  _picorv32_timer(COUNT);
  print_str("\r\nHello from PicoSoC !\r\n");

  char caractere;
    for(;;)
    {
      // reg_leds = 0xff;
      
      print("Assigning inputs");

      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x6d653162;
      reg_encryption_input = 0x31743261;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003362;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003465;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003563;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003661;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003766;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003865;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003162;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003261;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003362;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003465;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003563;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003661;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003766;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      reg_encryption_input = 0x00003865;
      // print("\n");
      // print_hex(reg_encryption_plaintext, 8);
      print("Assigning inputs done!\n");

      print("Plaintext:\n");
      print_hex(reg_encryption_plaintext, 8);

      print("\n");
      reg_encryption_start = 1;
      print_hex(reg_encryption_ready, 1);
      reg_encryption_start = 0;
      while(reg_encryption_ready == 0) {};

      print_hex(reg_encryption_ready, 1);
      print("\n");
      print("Encryption finished\n");

      for (int i = 0; i < 20; i++)
      {
        print_hex(reg_encryption_output, 8);
        print("\n");
      }

      do{
          caractere = getchar();
          reg_leds = 0;
      }
      while (caractere == 0xFF);
      print(&caractere);
    } 
}
