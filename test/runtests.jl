using RegularlySampledFormat
using Test

@testset "RegularlySampledFormat.jl" begin

# Tests for Par struct

pf = open("parfile.txt","w") 
Base.write(pf, "i1=2\n")
Base.write(pf, "s1=string\n")
close(pf)

RegularlySampledFormat.par = Par("julia",["-","i1=1","r1=2.0","b1=y","ns=1,2,3","par=parfile.txt"])

@test getint("i1") == 2
@test getfloat("r1") ≈ 2.0
@test getbool("b1") == true	
@test getints("ns", 3) == [1,2,3]
@test getstring("s1") == "string"

@test getprog(RegularlySampledFormat.par) == "julia"
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

# Tests for RSF file reading and writing

ENV["DATAPATH"] = "/some/value"
@test Datapath() == "/some/value"

delete!(ENV, "DATAPATH")
dp = open(".datapath","w") 
Base.write(dp, "datapath=/other/value")
close(dp)
@test Datapath() == "/other/value"
rm(".datapath")

@test Datapath() == "./"

# check that the temporary file is created in the correct directory    
ENV["TMPDATAPATH"] = "."
@test Temp()[1] == '.'

delete!(ENV, "TMPDATAPATH")
@test Temp()[1] == '.'

io = open("/dev/null", "w")
@test getfilename(io) == "/dev/null"
close(io)

io = open("/tmp/junk", "w")
@test getfilename(io) == :none
close(io)

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

inp = Input("mytest.rsf")

@test gettype(inp) == Float32
settype!(inp, Int32)
@test gettype(inp) == Int32

@test getform(inp) == "xdr"
setform!(inp, "native")
@test getform(inp) == "native"
setform!(inp, "ascii")
@test getform(inp) == "ascii"

putstring!(inp, "newkey", "newvalue")
@test getstring(inp, "newkey") == "newvalue"

@test tell(inp) == 0
@test bytes(inp) == 10 * sizeof(Float32)

out = Output("mytest_out.rsf")
@test gettype(out) == Float32
@test getform(out) == "native"	
settype!(out, Int32)
@test gettype(out) == Int32
setform!(out, "xdr")
@test getform(out) == "xdr"
putstring!(out, "newkey", "newvalue")
@test getstring(out, "newkey") == "newvalue"
@test getstring(out, "otherkey", "default") == "default"
@test getstring(out, "otherkey") == :none
putint!(out, "n1", 10)
putint!(out, "n2", 1)
putint!(out, "n3", 1)
@test getint(out, "n1") == 10
@test getint(out, "m1") == :none
@test getint(out, "m1", 1) == 1
putfloat!(out, "d1", 0.004f0)
@test getfloat(out, "d1") ≈ 0.004f0
@test getfloat(out, "d2") == :none
@test getfloat(out, "d2", 0.0f0) == 0.0f0
putints!(out, "ns", Int32[1, 2, 3], 3)
putfloats!(out, "fs", Float32[1.0, 2.0, 3.0], 3)
datawrite(out, Int32[0, 0, 0, 0, 1, 0, 0, 0, 0, 0])
@test getstring(out,"in") == :none # wrong?
setformat!(out, "ascii_byte")
@test getform(out) == "ascii"
@test gettype(out) == UInt8
@test getshape(out) == (10,)
fileclose(out)

@test getshape(inp) == (10,)

file = RSF("mytest.rsf")

@test getshape(file) == (10,)

data = ones(Float32, 5, 4)
file = RSF(data)

@test getshape(file) == (5, 4)

end