#include <stdio.h>

typedef void (*T)(float);

void call(T f) {
  f(1.0);
}

void f(float r) {
  printf("1337 %f\n", r);
}

int main(void) {
  call(&f);
}
