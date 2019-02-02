#include <stdio.h>
#include <stdlib.h>

#define BUFSIZE 1024*1024

int main(void) {
  FILE* f = fopen("/archive.rpa", "w");
  unsigned char buf[BUFSIZE] = "";
  for (int i = 0; i < BUFSIZE; i++) {
    buf[i] = rand() % 256;
  }
  for (int i = 0; i < 150; i++) {
    fwrite(buf, BUFSIZE, 1, f);
  }
  printf("Wrote file.\n");
}
