#include <SDL2/SDL.h>

static int decode_thread(void *arg) { return 0; }

int main(int argc, char* argv[]) {
  char buf[1024];
  SDL_LogSetAllPriority(SDL_LOG_PRIORITY_DEBUG);
  SDL_Thread *t = SDL_CreateThread(decode_thread, buf, NULL);
  printf("%p\n", t);  // NULL
  printf("%s\n", SDL_GetError());  // "SDL not built with thread support"
}
