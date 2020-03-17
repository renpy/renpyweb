#include <stdio.h>
#include <SDL2/SDL.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#define SAVEFILE "/home/web_user/.testbeforeunload/save.dat"
int count = 0;
int loaded = 0;

void load() {
  FILE* f = fopen(SAVEFILE, "rb");
  if (f == NULL) {
    perror("fopen");
    return;
  }
  fread(&count, sizeof(count), 1, f);
  fclose(f);
  printf("loaded count = %d\n", count);
}

void save() {
  FILE* f = fopen(SAVEFILE, "wb");
  if (f == NULL) {
    perror("fopen");
    return;
  }
  fwrite(&count, sizeof(count), 1, f);
  fclose(f);
  printf("saved count = %d\n", count);
#ifdef __EMSCRIPTEN__
  EM_ASM(
    console.log("saving...");
    // note: slight chance that FS.syncfs won't finish in time
    FS.syncfs(false, function(err){console.log("sync'd", err);});
  );
#endif
}

int SDLCALL beforeunload(void *userdata, SDL_Event * event)
{
  if (event->type == SDL_APP_TERMINATING) {
    EM_ASM(console.log("synchronous handler: SDL_APP_TERMINATING"););
    save();
  }
  return 1;
}

void one_iter() {
    SDL_Event ev = {};
#ifdef ASYNC
    SDL_WaitEvent(&ev);
#else
    SDL_PollEvent(&ev);
#endif

    int mounted = EM_ASM_INT(return Module.mounted);
    if (!mounted)
      return;

    if (!loaded) {
      load();
      loaded = 1;
    }

    if (ev.type == SDL_APP_TERMINATING) {
      // too late: may or may be reached depending on browser and page load
      EM_ASM(console.log("main loop: SDL_APP_TERMINATING"););
      // save();
    }
    if (ev.type == SDL_MOUSEBUTTONUP) {
      count++;
      printf("You clicked %d times\n", count);
    }
    if (ev.type == SDL_QUIT)
      // never reached with emscripten
      exit(0);
}

int main(int argc, char** argv) {
  SDL_Init(SDL_INIT_VIDEO);
  SDL_Window *sdlWindow = SDL_CreateWindow("test",
					   SDL_WINDOWPOS_UNDEFINED,
					   SDL_WINDOWPOS_UNDEFINED,
					   256, 256,
					   0);

  // Mount (async)
#ifdef __EMSCRIPTEN__
  EM_ASM(
    Module.mounted = false;
    FS.mkdir("/home/web_user/.testbeforeunload");
    FS.mount(IDBFS, {}, "/home/web_user/.testbeforeunload");
    FS.syncfs(true, function(err){
      Module.mounted = true;
      console.log("mounted", err);
    });
  );
#endif

  SDL_AddEventWatch(beforeunload, NULL);

#ifdef ASYNC
  while (1) { one_iter(); }
#else
  emscripten_set_main_loop(one_iter, -1, 1);
#endif

  SDL_Quit();
  return 0;
}

/*

EMCC_LOCAL_PORTS="sdl2emterpreter=$(pwd)/SDL2" emcc -DASYNC ../testbeforeunload.c -o index.html -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=index.em

EMCC_LOCAL_PORTS="sdl2emterpreter=$(pwd)/SDL2" emcc -DASYNC ../testbeforeunload.c -o index.html -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=index.em -s EMTERPRETIFY_WHITELIST='["_main","_SDL_RenderPresent","_GLES2_RenderPresent","_SDL_GL_SwapWindow","_Emscripten_GLES_SwapWindow","_SDL_WaitEvent", "_SDL_WaitEventTimeout", "_SDL_Delay", "_one_iter"]'

emcc ../testbeforeunload.c -o index.html -s USE_SDL=2
*/
