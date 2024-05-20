#include "firmware.h"
#include "irq_functions.h"
#include "irq.h"
#include "uart.h"
#include <stdbool.h>

// Pour l'IRQ
#define COUNT 100000000

// Les differents peripheriques presents sur le SoC
#define reg_uart_clkdiv (*(volatile uint32_t *)0x02000004)
#define reg_uart_data (*(volatile uint32_t *)0x02000008)
#define reg_input (*(volatile uint32_t *)0x0200000c)
#define reg_start (*(volatile uint32_t *)0x02000010)
#define reg_ready (*(volatile uint32_t *)0x02000014)
#define reg_output (*(volatile uint32_t *)0x02000018)
#define reg_leds (*(volatile uint32_t *)0x03000000)

int main(void)
{
  _picorv32_setmask(0);
  _picorv32_timer(COUNT);
  print_str("\r\nHello from PicoSoC !\r\n");

  char caractere;
  for (;;)
  {
    int mode = 2; // 0 = encryption, 1 = decryption, 2 = hash
    switch (mode)
    {
    case 0:
      print("===== Encryption mode ===== \n");
      print("Assigning inputs");
      reg_input = 0x6d653162;
      reg_input = 0x31743261;
      reg_input = 0x00003362;
      reg_input = 0x00003465;
      reg_input = 0x00003563;
      reg_input = 0x00003661;
      reg_input = 0x00003766;
      reg_input = 0x00003865;
      reg_input = 0x00003162;
      reg_input = 0x00003261;
      reg_input = 0x00003362;
      reg_input = 0x00003465;
      reg_input = 0x00003563;
      reg_input = 0x00003661;
      reg_input = 0x00003766;
      reg_input = 0x00003865;
      print("Assigning inputs done!\n");

      print("\n");
      reg_start = 1;
      print_hex(reg_ready, 1);
      reg_start = 0;
      while (reg_ready == 0)
      {
      };

      print_hex(reg_ready, 1);
      print("\n");
      print("Encryption finished\n");

      for (int i = 0; i < 19; i++)
      {
        print_hex(reg_output, 2);
      }
      print("\n");
      break;

    case 1:
      print("===== Decryption mode ===== \n");
      print("Assigning inputs");
      reg_input = 0x37653162;
      reg_input = 0xc2743261;
      reg_input = 0x00003362;
      reg_input = 0x00003465;
      reg_input = 0x00003563;
      reg_input = 0x00003661;
      reg_input = 0x00003766;
      reg_input = 0x00003865;
      reg_input = 0x00003162;
      reg_input = 0x00003261;
      reg_input = 0x00003362;
      reg_input = 0x00003465;
      reg_input = 0x00003563;
      reg_input = 0x00003661;
      reg_input = 0x00003766;
      reg_input = 0x00003865;
      print("Assigning inputs done!\n");

      print("\n");
      reg_start = 1;
      print_hex(reg_ready, 1);
      reg_start = 0;
      while (reg_ready == 0)
      {
      };

      print_hex(reg_ready, 1);
      print("\n");
      print("Decryption finished\n");

      for (int i = 0; i < 19; i++)
      {
        print_hex(reg_output, 2);
      }
      print("\n");
      break;

    case 2:
      print("===== Hash mode ===== \n");
      print("Assigning inputs");
      for (int i = 0; i < 2; i++)
      {
        reg_input = 0x62;
        reg_input = 0x6f;
        reg_input = 0x6e;
        reg_input = 0x6a;
        reg_input = 0x6f;
        reg_input = 0x75;
        reg_input = 0x72;
        reg_input = 0x63;
        reg_input = 0x72;
        reg_input = 0x79;
        reg_input = 0x70;
        reg_input = 0x74;
        reg_input = 0x69;
        reg_input = 0x73;
        reg_input = 0x6d;
        reg_input = 0x31;
      }
      print("Assigning inputs done!\n");

      print("\n");
      reg_start = 1;
      print_hex(reg_ready, 1);
      reg_start = 0;
      while (reg_ready == 0)
      {
      };

      print_hex(reg_ready, 1);
      print("\n");
      print("Hash finished\n");

      for (int i = 0; i < 33; i++)
      {
        print_hex(reg_output, 2);
      }
      print("\n");
      break;
      break;

    default:
      break;
    }

    do
    {
      caractere = getchar();
      reg_leds = 0;
    } while (caractere == 0xFF);
    print(&caractere);
  }
}
