#Original algorithm in C by John "nowl" on GitHub
#https://gist.github.com/nowl/828013
#Adapted to Python by Hayden Coffey
import sys
import multiprocessing
import time
SEED = 0

hash = [
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
    219]


def noise2(x, y):
  tmp = hash[(y + SEED) % 256]
  return hash[(tmp + x) % 256]


def lin_inter(x, y, s):
  return x + s * (y - x)


def smooth_inter(x, y, s):
  return lin_inter(x, y, s * s * (3 - 2 * s))


def noise2d(x, y):
  x_int = round(x)
  y_int = round(y)
  x_frac = x - x_int
  y_frac = y - y_int
  s = noise2(x_int, y_int)
  t = noise2(x_int + 1, y_int)
  u = noise2(x_int, y_int + 1)
  v = noise2(x_int + 1, y_int + 1)
  low = smooth_inter(float(s), float(t), x_frac)
  high = smooth_inter(float(u), float(v), x_frac)
  return smooth_inter(low, high, y_frac)


def perlin2d(x, y, freq, depth):
  xa = x * freq
  ya = y * freq
  amp = 1.0
  fin = 0.
  div = 0.0

  for _ in range(depth-1):
    div += 256 * amp
    fin += noise2d(xa, ya) * amp
    amp /= 2
    xa *= 2
    ya *= 2

  return fin / div


def run_perlin(X0, X1, Y0, Y1, Xlen, data):
  for y in range(int(Y0), int(Y1)):
    for x in range(int(X0), int(X1)):
      data[int(x) + int(y)*int(Xlen)] = perlin2d(float(x), float(y), 0.1, 4)


def main():
  if len(sys.argv) < 2:
    print("Usage {}: X Y (-verbose)\n", sys.argv[0])
    return 1

  XLIM = int(sys.argv[1])
  YLIM = int(sys.argv[2])

  verbose = False

  data = multiprocessing.Array('d', XLIM*YLIM)

  if len(sys.argv) == 4:
    verbose = True

  process_list = []
  start = time.time_ns()
  for y in range(0, YLIM, int(YLIM/multiprocessing.cpu_count())):
    #for x in range(0, XLIM, int(XLIM/multiprocessing.cpu_count())):
    tmp = multiprocessing.Process(target=run_perlin, args=(0, XLIM, y, y+YLIM/multiprocessing.cpu_count(), XLIM, data))
    tmp.start()
    process_list.append(tmp)
      #run_perlin(x+XLIM/multiprocessing.cpu_count(), y+YLIM/multiprocessing.cpu_count(), data)

  for proc in process_list:
    proc.join()

  end = time.time_ns()

  if verbose:
    for y in range(YLIM):
      for x in range(XLIM):
          print("{:-10f}".format(data[x + y*XLIM]), end='')
      print("")

  duration = (end - start) / (10 ** 9)

  print("Duration (s): {}".format(duration))
  return 0


main()
