#include <stdio.h>
#include <stdint.h>

int main() {
  FILE *f = fopen("fixture.dat", "w");

  fprintf(f, "This is a line of text.\n");
  fprintf(f, "And another one.\r\n");

  uint8_t bytes[3] =  {
    0x01,
    0x02,
    0xAB
  };
  fwrite(bytes, 3, sizeof(uint8_t), f);

  float floats[3] = {
    0.123456789,
    -9.87654321,
    3.14159
  };
  fwrite(floats, 3, sizeof(float), f);

  fclose(f);
}
