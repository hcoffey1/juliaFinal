#using Base.LinAlg.dot
using LinearAlgebra
fileName = ARGS[1]
vectorSize = parse(Int, ARGS[2])
iterCount = parse(Int, ARGS[3])


#print(fileName,"\n");
#print(vectorSize,"\n");
#print(iterCount,"\n");

#file = open(fileName, "r");

lines = readlines(fileName);

x = []
y = []

#lines = parse(Array{Float64,1}, lines)
for i in 1:(vectorSize*2)
    global x;
    global y;
    if i > vectorSize
        append!(y, (parse(Float64, lines[i])))
      else
        append!(x, (parse(Float64, lines[i])))
    end
end

print("Running dot product\n")
@time for i in 1:iterCount
  dot(x,y);
end