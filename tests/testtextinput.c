#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif
#include "SDL.h"

extern void InitVideo();
extern void Redraw();

char text[1024];
char *composition;
Sint32 cursor;
Sint32 selection_len;
SDL_bool done = SDL_FALSE;
SDL_Window *sdlWindow;

void Redraw(void) {
}

void loop(void) {
  SDL_Event event;
  if (SDL_PollEvent(&event)) {
    switch (event.type) {
    case SDL_QUIT:
      /* Quit */
      done = SDL_TRUE;
      break;
    case SDL_TEXTINPUT:
      /* Add new text onto the end of our text */
      strcat(text, event.text.text);
      SDL_Log("TEXTINPUT: %s %s\n", event.text.text, text);
      break;
    case SDL_TEXTEDITING:
      /*
	Update the composition text.
	Update the cursor position.
	Update the selection length (if any).
      */
      composition = event.edit.text;
      cursor = event.edit.start;
      selection_len = event.edit.length;
      SDL_Log("TEXTEDITING: %s %d %d\n", composition, cursor, selection_len);
      break;
    case SDL_KEYDOWN:
      SDL_Log("KEYDOWN: %s (%d)\n", SDL_GetKeyName(event.key.keysym.sym), event.key.keysym.sym);
      break;
    case SDL_KEYUP:
      SDL_Log("KEYUP: %s (%d)\n", SDL_GetKeyName(event.key.keysym.sym), event.key.keysym.sym);
      break;
    }
  }
  if (SDL_HasScreenKeyboardSupport()) {
    if (!SDL_IsTextInputActive() || !SDL_IsScreenKeyboardShown(sdlWindow)) {
      /* User killed the keyboard (e.g. with Android Back button), let's grab it back. */
      SDL_Log("Start text input\n");
      SDL_StartTextInput();    
    }
  }
  Redraw();
}

int main(int argc, char *argv[]) {
  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    return (1);
  }

  sdlWindow = SDL_CreateWindow("test",
					   SDL_WINDOWPOS_UNDEFINED,
					   SDL_WINDOWPOS_UNDEFINED,
					   640, 480,
					   0);
  SDL_Renderer *sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, 0);
  SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 255);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderPresent(sdlRenderer);
  
  SDL_Surface* screen = SDL_CreateRGBSurface(
    0, 640,480, 32,
    0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);

  SDL_Log("SDL_HasScreenKeyboardSupport=%d\n", SDL_HasScreenKeyboardSupport());
  
#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(loop, 0, 1);
#else
  while (!done) loop();
#endif
  
  SDL_Quit();
  
  return 0;
}

/*
  Synthetize from JS:
  document.getElementById('canvas').dispatchEvent(new KeyboardEvent('keydown',  { target:document.body, key:'f',code:'KeyF',keyCode:70, view:window, bubbles:true, cancelable:true }));
  document.getElementById('canvas').dispatchEvent(new KeyboardEvent('keypress', { target:document.body, key:'f',code:'KeyF',keyCode:70, view:window, bubbles:true, cancelable:true }));
  document.getElementById('canvas').dispatchEvent(new KeyboardEvent('keyup',    { target:document.body, key:'f',code:'KeyF',keyCode:70, view:window, bubbles:true, cancelable:true }));
*/

/**
 * Local Variables:
 * compile-command: "emcc -s USE_SDL=2 -s ASSERTIONS=1 -g testtextinput.c -o t/testtextinput.html"
 * End:
 */
