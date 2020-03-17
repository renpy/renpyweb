#include <stdio.h>
#include <SDL2/SDL.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

static int count = 0;
static SDL_Surface* screen = NULL;
static SDL_Texture* sdlTexture = NULL;
static SDL_Renderer* sdlRenderer = NULL;
static SDL_Window* sdlWindow = NULL;
static int run = 1;

void one_loop() {
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
    
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      printf("got event %d\n", event.type);

      if ((event.type == SDL_KEYDOWN) && (event.key.keysym.sym == SDLK_q))
	run = 0;

      if ((event.type == SDL_KEYDOWN) && (event.key.keysym.sym == SDLK_f)) {
	SDL_Log("toggling fullscreen (cur_state: %s)\n", (SDL_GetWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN) ? "YES" : "NO");
	SDL_SetWindowFullscreen(sdlWindow,
				(SDL_GetWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN)
				? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
	SDL_Log("toggled fullscreen (cur_state: %s)\n", (SDL_GetWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN) ? "YES" : "NO");
      }


      if (event.type == SDL_WINDOWEVENT) {
	  switch (event.window.event) {
	  case SDL_WINDOWEVENT_SHOWN:
	    SDL_Log("Window %d shown", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_HIDDEN:
	    SDL_Log("Window %d hidden", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_EXPOSED:
	    SDL_Log("Window %d exposed", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_MOVED:
	    SDL_Log("Window %d moved to %d,%d",
		    event.window.windowID, event.window.data1,
		    event.window.data2);
	    break;
	  case SDL_WINDOWEVENT_RESIZED:
	    SDL_Log("Window %d resized to %dx%d",
		    event.window.windowID, event.window.data1,
		    event.window.data2);
	    SDL_Log("fullscreen: %s\n", (SDL_GetWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN) ? "YES" : "NO");
	    break;
	  case SDL_WINDOWEVENT_SIZE_CHANGED:
	    SDL_Log("Window %d size changed to %dx%d",
		    event.window.windowID, event.window.data1,
		    event.window.data2);
	    SDL_Log("fullscreen: %s\n", (SDL_GetWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN) ? "YES" : "NO");
	    break;
	  case SDL_WINDOWEVENT_MINIMIZED:
	    SDL_Log("Window %d minimized", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_MAXIMIZED:
	    SDL_Log("Window %d maximized", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_RESTORED:
	    SDL_Log("Window %d restored", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_ENTER:
	    SDL_Log("Mouse entered window %d",
		    event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_LEAVE:
	    SDL_Log("Mouse left window %d", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_FOCUS_GAINED:
	    SDL_Log("Window %d gained keyboard focus",
		    event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_FOCUS_LOST:
	    SDL_Log("Window %d lost keyboard focus",
		    event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_CLOSE:
	    SDL_Log("Window %d closed", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_TAKE_FOCUS:
	    SDL_Log("Window %d is offered a focus", event.window.windowID);
	    break;
	  case SDL_WINDOWEVENT_HIT_TEST:
	    SDL_Log("Window %d has a special hit test", event.window.windowID);
	    break;
	  default:
	    SDL_Log("Window %d got unknown event %d",
		    event.window.windowID, event.window.event);
	    break;
	  }
	}
	if (event.type == SDL_QUIT)
	  run = 0;
	  break;
    }
}

int main(int argc, char** argv) {
  SDL_Init(SDL_INIT_VIDEO);
  /* sdlWindow = SDL_CreateWindow("test", */
  /* 					   SDL_WINDOWPOS_UNDEFINED, */
  /* 					   SDL_WINDOWPOS_UNDEFINED, */
  /* 					   800, 600, */
  /* 					   SDL_WINDOW_RESIZABLE); */
  /* sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, 0); */
  SDL_CreateWindowAndRenderer(800, 600, SDL_WINDOW_RESIZABLE, &sdlWindow, &sdlRenderer);
  SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 255);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderPresent(sdlRenderer);

  screen = SDL_CreateRGBSurface(0, 256,256, 32,
					    0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
  sdlTexture = SDL_CreateTexture(sdlRenderer,
					      SDL_PIXELFORMAT_ARGB8888,
					      SDL_TEXTUREACCESS_STREAMING,
					      256, 256);

  SDL_Rect r = {};
  SDL_GetDisplayBounds(0, &r);
  printf("SDL_GetDisplayBounds = %d %d %d %d\n", r.x, r.y, r.w, r.h);

  SDL_Log("Testing SDL_Log\n");  // console only
  
#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(one_loop, 0, 1);
  //while (run) one_loop();
#else
  while (run) one_loop();
#endif

  return 0;
}

/*
gcc $(sdl2-config --cflags --libs) ../testfullscreen.c -o testfullscreen && ./testfullscreen

emcc -s USE_SDL=2 ../testfullscreen.c -o testfullscreen.html

emcc -s USE_SDL=2 ../testfullscreen.c -o testfullscreen.html --shell-file testfullscreen-shell.html -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=index.em -s EMTERPRETIFY_WHITELIST='["_main","_SDL_RenderPresent","_GLES2_RenderPresent","_SDL_GL_SwapWindow","_Emscripten_GLES_SwapWindow","_SDL_WaitEvent", "_SDL_WaitEventTimeout", "_SDL_Delay", "_one_loop"]' -s ASSERTIONS=1 -g
*/
