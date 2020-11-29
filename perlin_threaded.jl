#Original algorithm in C by John "nowl" on GitHub
#https://gist.github.com/nowl/828013
#Adapted to Julia by Hayden Coffey
#TODO: Look at stability section in docs to improve performance
using Printf
SEED = 0;

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
    219];

function noise2(x::Int, y::Int)::Int
  local tmp::Int = hash[1 + (y + SEED) % 256];
  return hash[1 + (tmp + x) % 256];
end

function lin_inter(x::Float64, y::Float64, s::Float64)::Float64
  return x + s * (y - x);
end

function smooth_inter(x::Float64, y::Float64, s::Float64)::Float64
  return lin_inter(x, y, s * s * (3 - 2 * s));
end

function noise2d(x::Float64, y::Float64)::Float64
  x_int::Int = round(x);
  y_int::Int = round(y);
  x_frac::Float64 = x - x_int;
  y_frac::Float64 = y - y_int;
  s::Int = noise2(x_int, y_int);
  t::Int = noise2(x_int + 1, y_int);
  u::Int = noise2(x_int, y_int + 1);
  v::Int = noise2(x_int + 1, y_int + 1);
  low::Float64 = smooth_inter(Float64(s), Float64(t), x_frac);
  high::Float64 = smooth_inter(Float64(u), Float64(v), x_frac);
  return smooth_inter(low, high, y_frac);
end

function perlin2d(x::Float64, y::Float64, freq::Float64, depth::Int)::Float64
  xa::Float64 = x * freq;
  ya::Float64 = y * freq;
  amp::Float64 = 1.0;
  fin::Float64 = 0.;
  div::Float64 = 0.0;

  for i = 0:(depth-1)
    div += 256 * amp;
    fin += noise2d(xa, ya) * amp;
    amp /= 2;
    xa *= 2;
    ya *= 2;
  end

  return fin / div;
end

function run_perlin(X::Int,Y::Int, data::Array{Float64,1})
  Threads.@threads for y = 0:Y
    Threads.@threads for x = 0:X
      data[(x+1) + y*X] = perlin2d(Float64(x), Float64(y), 0.1, 4);
    end
  end
end

function main()::Int
  if size(ARGS)[1] < 2
    @printf("Usage %s: X Y (-verbose)\n", PROGRAM_FILE);
    return 1;
  end
  XLIM = parse(Int, ARGS[1]) - 1;
  YLIM = parse(Int, ARGS[2]) - 1;

  verbose = false;

  data = rand((XLIM+1)*(YLIM+1));

  if size(ARGS)[1] == 3
    verbose = true;
  end

  @time run_perlin(XLIM, YLIM, data);

  if verbose
    for y = 0:YLIM
      for x = 0:XLIM
        @printf("%-10lf", data[(x+1) + y*XLIM]);
      end
      @printf("\n");
    end
  end

  return 0;
end

main()