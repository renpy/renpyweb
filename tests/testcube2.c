#include <stdio.h>
#include <SDL2/SDL.h>

void dummy(void) { printf("testing EMTERPRETIFY_BLACKLIST\n"); }

#ifdef ASYNC
#include <emscripten.h>
extern void (*emscripten_sdl_async_callback)(Uint32);
void async_callback(Uint32 ms) {
  emscripten_sleep_with_yield(ms);
}
#endif

int main(int argc, char** argv) {
  SDL_Init(SDL_INIT_VIDEO);

#ifdef ASYNC
  emscripten_sdl_async_callback = async_callback;
#endif

  SDL_Window *sdlWindow = SDL_CreateWindow("test",
					   SDL_WINDOWPOS_UNDEFINED,
					   SDL_WINDOWPOS_UNDEFINED,
					   256, 256,
					   0);
  SDL_Renderer *sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, 0);
  SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 255);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderPresent(sdlRenderer);

  SDL_Surface* screen = SDL_CreateRGBSurface(0, 256,256, 32,
					    0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
  SDL_Texture* sdlTexture = SDL_CreateTexture(sdlRenderer,
					      SDL_PIXELFORMAT_ARGB8888,
					      SDL_TEXTUREACCESS_STREAMING,
					      256, 256);

  SDL_Rect r = {};
  SDL_GetDisplayBounds(0, &r);
  printf("SDL_GetDisplayBounds = %d %d %d %d\n", r.x, r.y, r.w, r.h);

  printf("SDL_EventState(SDL_KEYDOWN) = %d\n", SDL_EventState(SDL_KEYDOWN, -1));
  printf("SDL_EventState(SDL_MOUSEBUTTONDOWN) = %d\n", SDL_EventState(SDL_MOUSEBUTTONDOWN, -1));
  printf("SDL_EventState(SDL_FINGERDOWN) = %d\n", SDL_EventState(SDL_FINGERDOWN, -1));

  SDL_EventState(SDL_FINGERDOWN, 0);
  SDL_EventState(SDL_FINGERUP, 0);
  SDL_EventState(SDL_FINGERMOTION, 0);
  printf("SDL_EventState(SDL_FINGERDOWN) = %d\n", SDL_EventState(SDL_FINGERDOWN, -1));
  printf("SDL_EventState(SDL_FINGERUP) = %d\n", SDL_EventState(SDL_FINGERUP, -1));
  printf("SDL_EventState(SDL_FINGERMOTION) = %d\n", SDL_EventState(SDL_FINGERMOTION, -1));

  SDL_Log("Testing SDL_Log\n");  // console only
  
  int count = 0;
  while (1) {
    count++;
    if (SDL_MUSTLOCK(screen)) SDL_LockSurface(screen);
    for (int i = 0; i < 256; i++) {
      for (int j = 0; j < 256; j++) {
	int alpha = 255;
	*((Uint32*)screen->pixels + i * 256 + j) = SDL_MapRGBA(screen->format, i, j, 255-i+count, alpha);
      }
    }
    if (SDL_MUSTLOCK(screen)) SDL_UnlockSurface(screen);
    
    SDL_UpdateTexture(sdlTexture, NULL, screen->pixels, 256 * sizeof (Uint32));
    SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
    SDL_RenderPresent(sdlRenderer);
    
    SDL_Event ev;
    SDL_WaitEvent(&ev);
    printf("got event %d\n", ev.type);
    if (ev.type == SDL_MOUSEBUTTONDOWN) {
      printf("sdl_mousebuttondown %d %d\n", ev.button.button, ev.button.which);
    }
    if (ev.type == SDL_MOUSEBUTTONUP) {
      printf("sdl_mousebuttonup %d %d\n", ev.button.button, ev.button.which);
    }
    if (ev.type == SDL_MOUSEMOTION) {
      printf("sdl_mousemotion %d %d\n", ev.motion.which, ev.motion.which);
    }
    if (ev.type == SDL_FINGERDOWN) {
      printf("sdl_fingerdown\n");
    }
    if (ev.type == SDL_FINGERUP) {
      printf("sdl_fingerup\n");
    }
    if (ev.type == SDL_FINGERMOTION) {
      printf("sdl_fingermotion\n");
    }
    if (ev.type == SDL_QUIT)
      break;
  }

  printf("you should see a smoothly-colored square - no sharp lines but the square borders!\n");
  printf("and here is some text that should be HTML-friendly: amp: |&| double-quote: |\"| quote: |'| less-than, greater-than, html-like tags: |<cheez></cheez>|\nanother line.\n");

  SDL_Quit();

  dummy();

  return 0;
}

/*
gcc $(sdl2-config --cflags --libs) testcube2.c -o testcube2

EMCC_LOCAL_PORTS="sdl2=$(pwd)/../../build/SDL2" emcc -DASYNC ../testcube2.c -o testcube2.html -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=index.em -s EMTERPRETIFY_BLACKLIST='["_dummy"]'
EMCC_LOCAL_PORTS="sdl2=$(pwd)/../../build/SDL2" emcc -DASYNC ../testcube2.c -o testcube2.html -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=index.em -s EMTERPRETIFY_WHITELIST='["_main","_SDL_RenderPresent","_GLES2_RenderPresent","_SDL_GL_SwapWindow","_Emscripten_GLES_SwapWindow","_SDL_WaitEvent", "_SDL_WaitEventTimeout", "_SDL_Delay", "_async_callback"]'
emcc ../cube2.c -o index.html -s USE_SDL=2 -s USE_PTHREADS=1 -s PROXY_TO_PTHREAD=1 -s WASM=0
*/
