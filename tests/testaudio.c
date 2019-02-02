/**
 * Simple sine wave audio test
 */
#include <SDL2/SDL.h>
#include <math.h>
#include <stdio.h>

SDL_AudioSpec desired = {}, obtained = {};

static const char *format2string(Uint16 format) {
  char *format_str = "Unknown";
  switch (format)
    {
    case AUDIO_U8: format_str = "AUDIO_U8"; break;
    case AUDIO_S8: format_str = "AUDIO_S8"; break;
    case AUDIO_U16LSB: format_str = "AUDIO_U16LSB"; break;
    case AUDIO_S16LSB: format_str = "AUDIO_S16LSB"; break;
    case AUDIO_U16MSB: format_str = "AUDIO_U16MSB"; break;
    case AUDIO_S16MSB: format_str = "AUDIO_S16MSB"; break;
    case AUDIO_S32LSB: format_str = "AUDIO_S32LSB"; break;
    case AUDIO_S32MSB: format_str = "AUDIO_S32MSB"; break;
    case AUDIO_F32LSB: format_str = "AUDIO_F32LSB"; break;
    case AUDIO_F32MSB: format_str = "AUDIO_F32MSB"; break;
    }
  return format_str;
}

static unsigned int x = 0;
static unsigned int callback_count = 0;
static unsigned int callback_count_start = 0;
static void callback(void *userdata, Uint8 *stream, int length) {
  /* printf("callback\n"); */
  unsigned int now = SDL_GetTicks();
  unsigned int delta_ms = now - callback_count_start;
  if (delta_ms > 500) {
    double cps = 1.0 * callback_count / delta_ms * 1000;
    printf("callback: %.02fHz\n", cps);
    //fflush(stdout);
    callback_count = 0;
    callback_count_start = now;
  }
  callback_count++;

  float vol = .5;
  unsigned int pitch = 440;
  if (obtained.format == AUDIO_F32LSB || obtained.format == AUDIO_F32MSB) {
    float* s = (float*) stream;
    length /= sizeof(float);
    length /= obtained.channels;
    for (int i = 0; i < length; i++) {
      for (int j = 0; j < obtained.channels; j++) {
	s[i*obtained.channels + j] = sin(x * pitch * 2*M_PI / obtained.freq) * vol;
      }
      x++;
    }
  } else { /* assuming we got AUDIO_S16SYS */
    Sint16* s = (Sint16*) stream;
    length /= sizeof(Sint16);
    length /= obtained.channels;
    for (int i = 0; i < length; i++) {
      for (int j = 0; j < obtained.channels; j++) {
	s[i*obtained.channels + j] = sin(x * pitch * 2*M_PI / obtained.freq) * vol \
	  * pow(2,15);
      }
      x++;
    }
  }
}

int main(int argc, char* argv[]) {
  printf("starting...\n");
  printf("sizeof(float): %lu\n", sizeof(float));
  printf("sizeof(double): %lu\n", sizeof(double));

  if (SDL_Init(SDL_INIT_AUDIO)) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }

  /* for (int i = 0; i < SDL_GetNumAudioDrivers(); ++i) { */
  /*   const char* driver_name = SDL_GetAudioDriver(i); */
  /*   printf("driver %s\n", driver_name); */
  /*   if (SDL_AudioInit(driver_name) != 0) { */
  /*     printf("Audio driver failed to initialize: %s\n", driver_name); */
  /*     continue; */
  /*   } else { */
  /*     break; */
  /*   } */
  /* } */
  
  desired.freq = 48000;
  desired.format = AUDIO_S16SYS;
  /* desired.format = AUDIO_F32SYS; */
  desired.channels = 2;
  desired.samples = 2048;
  desired.callback = callback;
  desired.userdata = NULL;
  
  /* if (SDL_OpenAudio(&desired, &obtained)) { */
  /*   fprintf(stderr, "SDL_OpenAudio: %s\n", SDL_GetError()); */
  /*   return 1; */
  /* } */
  /* Force S16SYS format */
  obtained = desired;
  if (SDL_OpenAudio(&obtained, NULL)) {
    fprintf(stderr, "SDL_OpenAudio: %s\n", SDL_GetError());
    return 1;
  }

  printf("Freq: %d\n", obtained.freq);
  printf("Format: %s (0x%X)\n", format2string(obtained.format), obtained.format);
  printf("Channels: %d\n", obtained.channels);
  printf("Samples: %d\n", obtained.samples);

  SDL_PauseAudio(0); /* start audio playing. */
  SDL_Delay(10000);
  SDL_PauseAudio(1);

  SDL_CloseAudio();
  SDL_Quit();
  printf("end.\n");
}

/* EMCC_LOCAL_PORTS="sdl2=$HOME/workdir/emsource/ports/SDL2-version_13|SDL2-version_13" emcc ../testaudio.c -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_WHITELIST='["_main","_SDL_Delay"]' -g3 -o testaudio.html */
