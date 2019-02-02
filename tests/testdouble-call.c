static void (*pf)(float, float, float, float);
void call_pf() {
  pf(1.0, 1.0, 1.0, 1.0);
}
void set_pf(void (*f)(float, float, float, float)) {
  pf = f;
}
