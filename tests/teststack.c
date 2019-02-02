#include <stdio.h>
static int i = 1;
void rec() { ++i; rec(); }
int main(void) { rec(); printf("%d\n", i); }
