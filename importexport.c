/*
Import/export ~/.renpy/ as .zip

Copyright (C) 2018, 2019  Sylvain Beucler

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <zip.h>

#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <errno.h>
#include <libgen.h>
#include <sys/types.h>
#include <utime.h>

int mkdir_rec(char* path) {
  int ret;
  mode_t mode = 00755;
  ret = mkdir(path, mode);
  if (ret == 0 || errno == EEXIST) {
    return 0;
  } else {
    char* dir = strdup(path);
    dirname(dir);
    ret = mkdir_rec(dir);
    free(dir);
    if (ret < 0) {
      return ret;
    }
    if ((ret = mkdir(path, mode)) < 0) {
      perror("mkdir");
      return ret;
    } 
    return 0;
  }
}

int IsDir(char* path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

int AddFileToZip(zip_t* archive, char* path, char* prefix) {
  zip_source_t *s;
  s = zip_source_file(archive, path, 0, -1);
  if (s == NULL) {
    fprintf(stderr, "error opening %s\n", path);
    return 0;
  }
  char* zippath = path + strlen(prefix);
  if (zip_file_add(archive, zippath, s, ZIP_FL_ENC_UTF_8) < 0) { 
    zip_source_free(s);
    fprintf(stderr, "error adding %s: %s\n", path, zip_strerror(archive));
    return 0;
  }
  return 1;
}

int AddPathToZip(zip_t* archive, char* path, char* prefix) {
  //printf("processing %s\n", path);
  struct stat st;
  if (IsDir(path)) {
    DIR* dir = opendir(path);
    if (dir == NULL) {
      perror("opendir");
      return 0;
    }
    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
      //printf("dir: %s\n", ent->d_name);
      if (strcmp(ent->d_name, ".") == 0) continue;
      if (strcmp(ent->d_name, "..") == 0) continue;
      char* subpath = malloc(strlen(path) + 1 + strlen(ent->d_name) + 1);
      sprintf(subpath, "%s/%s", path, ent->d_name);
      AddPathToZip(archive, subpath, prefix);
      free(subpath);
    }
    closedir(dir);
  } else {
    AddFileToZip(archive, path, prefix);
  }
  return 1;
}

int emSavegamesExport(void) {
  int errorp;
  zip_t* archive = zip_open("savegames.zip", ZIP_CREATE|ZIP_TRUNCATE|ZIP_CHECKCONS, &errorp);
  if (archive == NULL) {
    zip_error_t error;
    zip_error_init_with_code(&error, errorp);
    fprintf(stderr, "error creating savegames.zip: %s\n", zip_error_strerror(&error));
    zip_error_fini(&error);
    return 0;
  }

  char* path = malloc(strlen(getenv("HOME"))+1+strlen(".renpy")+1);
  sprintf(path, "%s/%s", getenv("HOME"), ".renpy");
  char* prefix = malloc(strlen(getenv("HOME"))+1+strlen(".renpy")+1+1);
  sprintf(prefix, "%s/%s/", getenv("HOME"), ".renpy");
  AddPathToZip(archive, path, prefix);
  free(path);

  if (zip_get_num_entries(archive, 0) == 0) {
    printf("No savegames found!\n");
    return 0;
  } else if (zip_close(archive) < 0) {
    fprintf(stderr, "cannot write savegames.zip: %s\n", zip_strerror(archive));
    return 0;
  }

  chmod("savegames.zip", 00666);
  return 1;
}

void emSavegamesImport(void) {
  int errorp;
  zip_t* archive = zip_open("/savegames.zip", ZIP_RDONLY, &errorp);
  if (archive == NULL) {
    zip_error_t error;
    zip_error_init_with_code(&error, errorp);
    fprintf(stderr, "error opening savegames.zip: %s\n", zip_error_strerror(&error));
    zip_error_fini(&error);
    return;
  }

  char* prefix = malloc(strlen(getenv("HOME"))+1+strlen(".renpy")+1+1);
  sprintf(prefix, "%s/%s/", getenv("HOME"), ".renpy");
  for (int i = 0; i < zip_get_num_entries(archive, 0); i++) {
    zip_stat_t sb;
    zip_stat_index(archive, i, 0, &sb);
    if (!(sb.valid & ZIP_STAT_NAME)
	|| !(sb.valid & ZIP_STAT_SIZE)) {
      continue;
    }

    if (sb.name[strlen(sb.name)-1] == '/') {
      // will recursively create directories later
      continue;
    }

    char* destFullPath = malloc(strlen(prefix)+strlen(sb.name)+1);
    sprintf(destFullPath, "%s%s", prefix, sb.name);
    char* dir = strdup(destFullPath);
    dirname(dir);
    int ret = mkdir_rec(dir);
    if (ret < 0) printf("Error creating directory %s\n", dir);
    free(dir);
    if (ret < 0)
      continue;

    zip_file_t* file;
    if ((file = zip_fopen_index(archive, i, 0)) == NULL) {
      fprintf(stderr, "error opening file %d: %s\n", i, zip_strerror(archive));
      continue;
    }
    FILE* out;
    if ((out = fopen(destFullPath, "wb")) == NULL) {
      perror("fopen");
      continue;
    }
    
    unsigned char buf[4096];  // size from emscripten implementation
    zip_uint64_t total = 0;
    while (total < sb.size) {
      zip_int64_t nb_read;
      if ((nb_read = zip_fread(file, buf, sizeof(buf))) < 0) {
	fprintf(stderr, "error reading %s: %s\n", sb.name, zip_file_strerror(file));
	continue;
      }
      fwrite(buf, nb_read, 1, out);
      total += nb_read;
    }
    fclose(out);
    zip_fclose(file);

    if (sb.valid | ZIP_STAT_MTIME) {
      struct utimbuf times = { sb.mtime, sb.mtime };
      utime(destFullPath, &times);
    }

    free(destFullPath);
  }
}

#ifdef TEST
int main(void) {
  return !emSavegamesExport();
}
#endif
