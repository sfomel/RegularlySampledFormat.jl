using RegularlySampledFormat
using Test

@testset "RegularlySampledFormat.jl" begin

# [TEST CASE 2]:  Test for inputing parameters from a symbolic table

t = SimTab()
enter!(t, "key", "value")
enter!(t, "int", "25")

@test getint(t, "int") == (true, 25)

enter!(t, "ints", "2,3,4")

@test getints(t, "ints", 3) == (true, [2, 3, 4])

# [TEST CASE 2]:  Test for inputing parameters from a header file
  
io = open("myfile.txt", "w")
Base.write(io, "Hello world! \n a=1 b=4 \n c=3\n")
close(io)

file = open("myfile.txt")
t = SimTab()
input!(t, file)
close(file)

@test getint(t, "b") == (true, 4)

end
