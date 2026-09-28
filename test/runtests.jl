using RegularlySampledFormat
using Test

@testset "RegularlySampledFormat.jl" begin

# [TEST CASE 1]:  Test for inputing parameters from the header file
  
io = open("myfile.txt", "w")
Base.write(io, "Hello world! \n a=1 b=4 \n c=3\n")
close(io)

file = open("myfile.txt")
t = SimTab()
input!(t, file)
close(file)

@test getint(t, "b") == (true, 4)

end
