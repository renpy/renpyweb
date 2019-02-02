#include <stdio.h>
void set_pf(void (*f)(float, float, float, float));
void call_pf(void);

void f(float r, float g, float b, float a) {
  printf("%f,%f,%f,%f\n", r,g,b,a);
}
int main(void) {
  set_pf(&f);
  call_pf();
}
