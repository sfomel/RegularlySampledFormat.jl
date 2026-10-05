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
@test getint("c") == :none
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
@test getints("ints", 2, [1,2,3]) == [1,2]
@test getfloats("ints", 6, [1.0,2.0,3.0]) ≈ [1.0,2.0,3.0,3.0,3.0,3.0]
@test getbools("ints", 6, [true,false,true]) == [true,false,true,true,true,true]

# [TEST CASE 4]:  Test for RSF file reading and writing

ENV["DATAPATH"] = "/some/value"
@test Datapath() == "/some/value"

# check that the temporary file is created in the correct directory    
ENV["TMPDATAPATH"] = "."
@test Temp()[1] == '.' 

io = open("mytest.rsf", "w")
Base.write(io, """
4.3-git	sfspike	Users/sfomel/RSFSRC:	sfomel@GEO-A78312	Fri Oct  2 15:37:15 2026

	o1=0
	label1="Time"
	data_format="native_float"
	esize=4
	in="stdout"
	unit1="s"
	d1=0.004
	n1=10
	in="stdin"

4.3-git	sfdd	Users/sfomel/RSFSRC:	sfomel@GEO-A78312	Fri Oct  2 15:37:15 2026

	data_format="xdr_float"
	esize=4
	in="mytest.rsf@"
""")
close(io)

io = open("mytest.rsf@", "w")
Base.write(io, Float32[0, 0, 0, 0, 1, 0, 0, 0, 0, 0])
close(io)

rsf = _RSF(true, "mytest.rsf")

@test gettype(rsf) == Float32
settype!(rsf, Int32)
@test gettype(rsf) == Int32

@test getform(rsf) == "xdr"
setform!(rsf, "native")
@test getform(rsf) == "native"
setform!(rsf, "ascii")
@test getform(rsf) == "ascii"

putstring!(rsf, "newkey", "newvalue")
@test getstring(rsf, "newkey") == "newvalue"

@test tell(rsf) == 0
@test bytes(rsf) == 10 * sizeof(Float32)

inp = Input("mytest.rsf")
@test gettype(inp) == Float32
@test getform(inp) == "xdr"
@test getint(inp, "n1") == 10

out = Output("mytest_out.rsf")
@test gettype(out) == Float32
@test getform(out) == "native"	

@test getshape(inp) == (10,)

file = RSF("mytest.rsf")

@test getshape(file) == (10,)

data = ones(Float32, 5, 4)
file = RSF(data)

@test getshape(file) == (5, 4)

end
