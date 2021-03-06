// Written by John "nowl" on GitHub
// https://gist.github.com/nowl/828013
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define TRUE 1
#define FALSE 0

static int SEED = 0;

static int hash[] = {
    208, 34,  231, 213, 32,  248, 233, 56,  161, 78,  24,  140, 71,  48,  140,
    254, 245, 255, 247, 247, 40,  185, 248, 251, 245, 28,  124, 204, 204, 76,
    36,  1,   107, 28,  234, 163, 202, 224, 245, 128, 167, 204, 9,   92,  217,
    54,  239, 174, 173, 102, 193, 189, 190, 121, 100, 108, 167, 44,  43,  77,
    180, 204, 8,   81,  70,  223, 11,  38,  24,  254, 210, 210, 177, 32,  81,
    195, 243, 125, 8,   169, 112, 32,  97,  53,  195, 13,  203, 9,   47,  104,
    125, 117, 114, 124, 165, 203, 181, 235, 193, 206, 70,  180, 174, 0,   167,
    181, 41,  164, 30,  116, 127, 198, 245, 146, 87,  224, 149, 206, 57,  4,
    192, 210, 65,  210, 129, 240, 178, 105, 228, 108, 245, 148, 140, 40,  35,
    195, 38,  58,  65,  207, 215, 253, 65,  85,  208, 76,  62,  3,   237, 55,
    89,  232, 50,  217, 64,  244, 157, 199, 121, 252, 90,  17,  212, 203, 149,
    152, 140, 187, 234, 177, 73,  174, 193, 100, 192, 143, 97,  53,  145, 135,
    19,  103, 13,  90,  135, 151, 199, 91,  239, 247, 33,  39,  145, 101, 120,
    99,  3,   186, 86,  99,  41,  237, 203, 111, 79,  220, 135, 158, 42,  30,
    154, 120, 67,  87,  167, 135, 176, 183, 191, 253, 115, 184, 21,  233, 58,
    129, 233, 142, 39,  128, 211, 118, 137, 139, 255, 114, 20,  218, 113, 154,
    27,  127, 246, 250, 1,   8,   198, 250, 209, 92,  222, 173, 21,  88,  102,
    219};

int noise2(int x, int y) {
  int tmp = hash[(y + SEED) % 256];
  return hash[(tmp + x) % 256];
}

double lin_inter(double x, double y, double s) { return x + s * (y - x); }

double smooth_inter(double x, double y, double s) {
  return lin_inter(x, y, s * s * (3 - 2 * s));
}

double noise2d(double x, double y) {
  int x_int = x;
  int y_int = y;
  double x_frac = x - x_int;
  double y_frac = y - y_int;
  int s = noise2(x_int, y_int);
  int t = noise2(x_int + 1, y_int);
  int u = noise2(x_int, y_int + 1);
  int v = noise2(x_int + 1, y_int + 1);
  double low = smooth_inter(s, t, x_frac);
  double high = smooth_inter(u, v, x_frac);
  return smooth_inter(low, high, y_frac);
}

double perlin2d(double x, double y, double freq, int depth) {
  double xa = x * freq;
  double ya = y * freq;
  double amp = 1.0;
  double fin = 0;
  double div = 0.0;

  int i;
  for (i = 0; i < depth; i++) {
    div += 256 * amp;
    fin += noise2d(xa, ya) * amp;
    amp /= 2;
    xa *= 2;
    ya *= 2;
  }

  return fin / div;
}

void run_perlin(int X, int Y, double *data) {
  int x, y;
#pragma omp parallel
  {
    for (y = 0; y < Y; y++)
      for (x = 0; x < X; x++)
        data[x + y * X] = perlin2d(x, y, 0.1, 4);
  }
}

void run_perlin_verbose(int X, int Y, double *data) {
  int x, y;
  for (y = 0; y < Y; y++) {
    for (x = 0; x < X; x++) {
      printf("%-10lf", perlin2d(x, y, 0.1, 4));
    }
    printf("\n");
  }
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    printf("Usage %s: X Y (-verbose)\n", argv[0]);
    return 1;
  }

  int XLIM = atoi(argv[1]);
  int YLIM = atoi(argv[2]);

  struct timespec start_time, finish_time;

  int verbose = FALSE;

  double *data = (double *)malloc(sizeof(double) * XLIM * YLIM);

  if (argc == 4) {
    verbose = TRUE;
  }

  clock_gettime(CLOCK_REALTIME, &start_time);
  run_perlin(XLIM, YLIM, data);
  clock_gettime(CLOCK_REALTIME, &finish_time);

  if (verbose == TRUE) {
    for(int i = 0; i < YLIM; i++)
    {
      for(int j = 0; j < XLIM; j++)
      {
        printf("%-10lf", data[j + i*XLIM]);
      }
      printf("\n");
    }
  }
  double time_taken = (finish_time.tv_sec - start_time.tv_sec) * 1e9;
  time_taken = (time_taken + (finish_time.tv_nsec - start_time.tv_nsec)) * 1e-9;
  printf("Duration (s): %lf\n", time_taken);
  return 0;
}