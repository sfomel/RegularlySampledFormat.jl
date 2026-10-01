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
@test getints(t, "ints", 2) == (true, [2, 3])
@test getints(t, "ints", 6) == (true, [2, 3, 4, 4, 4, 4])
@test getints(t, "none", 4) == (false, :none)

enter!(t, "float", "3.14")

@test getfloat(t, "float")[1] == true && getfloat(t, "float")[2] ≈ 3.14

@test getfloat(t, "int")[1] == true && getfloat(t, "int")[2] ≈ 25.0

@test getfloats(t, "ints", 6)[1] == true && getfloats(t, "ints", 6)[2] ≈ [2.0, 3.0, 4.0, 4.0, 4.0, 4.0]

@test getstring(t, "int") == "25"

enter!(t, "string", "\"3.14\"")

@test getstring(t, "string") == "3.14"
@test getstring(t, "none") == :none

enter!(t, "true", "yes")
enter!(t, "false", "no")

@test getbool(t, "true") == (true, true)
@test getbool(t, "false") == (true, false)
@test getbool(t, "none") == (false, :none)

enter!(t, "bools", "yes,no,1,0")

@test getbools(t, "bools", 4) == (true, [true, false, true, false])
@test getbools(t, "bools", 2) == (true, [true, false])
@test getbools(t, "bools", 6) == (true, [true, false, true, false, false, false])
@test getbools(t, "none", 4) == (false, :none)

add!(t, "key=val")
string!(t, "one=1 two=2 three=3 four")

@test getint(t, "two") == (true, 2)
@test getint(t, "four") == (false, :none)

# [TEST CASE 2]:  Test for inputing parameters from a header file
  
io = open("myfile.txt", "w")
Base.write(io, "\n\n\n Hello world! \n\n\n a=1 b=4 \n c=3\n")
close(io)

file = open("myfile.txt")
t = SimTab()
input!(t, file)
close(file)

@test getint(t, "b") == (true, 4)
@test getint(t, "c") == (true, 3)

file = open("myfile.txt")
io = open("outfile.txt", "w")
input!(t, file, io)
close(io)
close(file)

@test getint(t, "b") == (true, 4)

# [TEST CASE 3]:  Test for outputing parameters to a header file

fp = open("simtab.txt", "w")
output(t, fp)
close(fp)

file = open("simtab.txt")
t = SimTab()
input!(t, file)
close(file)

@test getint(t, "b") == (true, 4)

# [TEST CASE 3]:  Test for Par struct

par = Par("julia",["-"])

@test getprog(par) == "julia"
@test getint("b") == :none
@test getint("c", 4) == 4
@test getfloat("b") == :none
@test getfloat("b", 4.0) == 4.0
@test getbool("b") == :none
@test getbool("b", true) == true
@test getstring("b") == :none
@test getstring("b", "default") == "default"

@test getints("ints", 6) == :none
@test getfloats("ints", 6) == :none
@test getbools("ints", 6) == :none
@test getints("ints", 6, [1,2,3]) == [1,2,3,3,3,3]
@test getints("ints", 3, [1,2,3]) == [1,2,3]
@test getfloats("ints", 6, [1.0,2.0,3.0]) ≈ [1.0,2.0,3.0,3.0,3.0,3.0]
@test getbools("ints", 6, [true,false,true]) == [true,false,true,true,true,true]

# [TEST CASE 4]:  Test for RSF file reading and writing

ENV["DATAPATH"] = "/some/value"
@test Datapath() == "/some/value"

# check that the temporary file is created in the correct directory    
ENV["TMPDATAPATH"] = "."
@test Temp()[1] == '.' 

end
