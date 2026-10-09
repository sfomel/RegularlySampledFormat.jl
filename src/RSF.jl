# This file contains the main functions for reading and writing RSF files, 
# as well as some utility functions for handling RSF data.

using Printf
using Dates
using DelimitedFiles

"""
    Datapath() -> String

    Return the path to the data directory. The path is determined by checking the following sources in order of priority:
    1. The environment variable `DATAPATH`.
    2. A file named `.datapath` in the current working directory.
    3. A file named `.datapath` in the user's home directory.
    4. If none of the above sources provide a path, the function defaults to returning
    the current working directory (`"./"`).
"""
function Datapath()
	if haskey(ENV, "DATAPATH")
    	path = ENV["DATAPATH"]
	else
		path = nothing
        pathfile = nothing
        try
            pathfile = open(".datapath","r")
		catch
            try
                pathfile = open(joinpath(ENV["HOME"],".datapath"),"r")
			catch
                pathfile = nothing
			end
		end
        if pathfile != nothing
			re = r"(?:$(Base.Libc.gethostname())\s+)?datapath=(\S+)" 
            for line in readlines(pathfile)
				check = match(re, line)
                if check != nothing
                    path = check.captures[3]
				end
			end
            close(pathfile)
		end
    	if path == nothing
        	path = "./" # the ultimate fallback
		end
	end
    return path
end

"""
    Temp() -> (String, IO)

    Create a temporary data path. The temporary data path is determined by checking the following sources in order of priority:
    1. The environment variable `TMPDATAPATH`.
    2. The result of `Datapath()` function.
    
    Returns a tuple containing the path to the temporary file and an IO object for writing to the file.
"""
function Temp()
	if haskey(ENV, "TMPDATAPATH")
		tmpdatapath = ENV["TMPDATAPATH"]
	else
		tmpdatapath = Datapath()
	end
	temp, io = mktemp(tmpdatapath)
	return temp
end

"""
    getfilename(stream::IOStream) -> Union{String, Symbol}

    Find the name of the file associated with the given IO stream. 
    If the stream is not associated with a file, returns `:none`.
"""
function getfilename(stream::IOStream)
	found_stdout = false

	inode = stat(stream).inode
    f = "/dev/null"
    if inode == stat(f).inode
        found_stdout = true
    else        
        for fl in readdir(".")
            # Comparing the unique file ID stored by the OS for the file stream
            # with the known entries in the file table:
            if isfile(fl) && inode == stat(fl).inode
                found_stdout = true
                f = fl
                break
			end
		end
	end

    if found_stdout
        return f
    else
        return :none
	end
end

begin
	mutable struct _RSF
		stream::Union{IOStream, Symbol}
		pars::SimTab
		headname::Union{String, Symbol}
		head::Union{IOStream, Symbol}
		dataname::Union{String,Symbol}
		pipe::Bool
		type::DataType
		form::String
        aformat::Union{Printf.Format, Symbol}
        eformat::Union{Printf.Format, Symbol}
        aline::Int
	end
	
    _infiles = Vector{Union{_RSF, Symbol}}(undef, 1)
    _infiles[1] = :none

    """
        _RSF(inp::Bool, tag=nothing) -> _RSF

        Create an instance of the `_RSF` struct for reading or writing RSF files. 
        If `inp` is true, the function reads from an input RSF file specified by `tag`. 
        If `inp` is false, it prepares for writing to an output RSF file specified by `tag`.
    """
	function _RSF(inp::Bool, tag=nothing)
        global _infiles		
		if inp
			if tag==nothing || tag=="in"
				stream = stdin
				filename = :none
			else 
				filename = getstring(tag)
				if filename == :none
					filename = tag
				end
				stream = open(filename,"r+")
			end
			headname = Temp()
			head = open(headname, "w")
			# read parameters
			pars = SimTab()
			input!(pars, stream, head)
			# get dataname
            filename = getstring(pars,"in")
            if filename == :none
				throw("No in= in file '$tag' ")
			end
			dataname = filename
			# keep stream in the special case of in=stdin
			if filename != "stdin"
				stream = open(filename,"r+")
			end
			new = _RSF(stream, pars, headname, head, dataname, false, Float32, "native", :none, :none, 8)
			# keep track of input files
            if filename == :none
				_infiles[1] = new
			else
				push!(_infiles, new)
			end
            # set format
            data_format = getstring(pars, "data_format")
            if data_format == :none
                data_format = "ascii_float"
            end
            setformat!(new, data_format)
			return new
		else # output
			if tag==nothing || tag=="out"
				stream = stdout
				filename = :none
			else
                filename = getstring(tag)
				if filename == :none
					filename = tag
				end
				stream = open(filename,"w+")
			end
			# try piping
            pipe = true
			try
				t = position(stream)
                pipe = false
            catch
                pipe = true
			end
			if stream == stdout
				filename = getstring("--out") || getstring("out")
            else
                filename = :none
			end
			if pipe
                dataname = "stdout"
			elseif filename == :none
                path = Datapath()
                name = getfilename(stream)
				if name != :none
                    if name == "/dev/null"
                        dataname = "stdout"
                    else
                        dataname = joinpath(path, name * "@")
					end
                else
                    # invent a name
                    dataname = Temp()
				end
            else
                dataname = filename
			end
			new = _RSF(stream, SimTab(), :none, :none, dataname, pipe, Float32, "native", :none, :none, 8)
            # set dataname
            putstring!(new, "in", dataname)
            # set format
            if _infiles[1] != :none
                data_format = getstring(_infiles[1], "data_format", "native_float")
            else
                data_format = "native_float" 
            end 
            setformat!(new, data_format)
            return new
		end
	end
end

begin
	mutable struct Input
		file::_RSF
	end
    """
    Input(tag::String) -> Input

    Create an instance of the `Input` struct for reading from an RSF file specified by `tag`.
    """
	Input(tag::String) = Input(_RSF(true,tag))
end

begin
	mutable struct Output
		file::_RSF
	end
    """
    Output(tag::String) -> Output

    Create an instance of the `Output` struct for writing to an RSF file specified by `tag`.    
    """
	Output(tag::String) = Output(_RSF(false,tag))
end

"""
    gettype(rsf::_RSF) -> DataType

    Return the data type of the RSF file represented by the `_RSF` struct.
"""
gettype(rsf::_RSF) = rsf.type
gettype(inp::Input) = gettype(inp.file)
gettype(out::Output) = gettype(out.file)

"""
    settype!(rsf::_RSF, T::DataType)

    Set the data type of the RSF file represented by the `_RSF` struct to `T`.
"""
function settype!(rsf::_RSF, T::DataType)
	rsf.type = T
end

setform!(rsf::Input, form::String) = setform!(rsf.file, form)
setform!(rsf::Output, form::String) = setform!(rsf.file, form)  

settype!(rsf::Input, T::DataType) = settype!(rsf.file, T)  
settype!(rsf::Output, T::DataType) = settype!(rsf.file, T)  

"""
    putint!(rsf::_RSF, key::String, par::Int)

    Write an integer parameter to the RSF file represented by the `_RSF` struct. 
    The parameter is associated with the specified `key`.
"""
function putint!(rsf::_RSF, key::String, par::Integer)
    if :none == rsf.dataname
        throw("putint to a closed file")
	end
    val = "$par"
    enter!(rsf.pars, key, val)
end

putint!(rsf::Output, key::String, par::Integer) = putint!(rsf.file, key, par)

"""
    putints!(rsf::_RSF, key::String, par::Array{Int}, n::Int)   

    Write an array of integer parameters to the RSF file represented by the `_RSF` struct.
    The parameters are associated with the specified `key`. The array has length `n`.
"""
function putints!(rsf::_RSF,key::String,par::Array{T},n::Int) where T <: Integer
    if :none == rsf.dataname
        throw("putints to a closed file")
	end
    val = ""
    for i in 1:n-1
        val *= "$(par[i]),"
	end
    val *= "$(par[n])"
    enter!(rsf.pars, key, val)
end

putints!(rsf::Output,key::String,par::Array{T},n::Int) where T <: Integer = putints!(rsf.file,key,par,n)

"""
    putfloat!(rsf::_RSF, key::String, val::Float32) -> Nothing

    Write a float parameter to the RSF file represented by the `_RSF` struct. 
    The parameter is associated with the specified `key`.
"""
function putfloat!(rsf::_RSF, key::String, par::AbstractFloat)
    if :none == rsf.dataname
        throw("putfloat to a closed file")
	end
    val = "$par"
    enter!(rsf.pars, key, val)
end

putfloat!(rsf::Output,key::String,val::AbstractFloat) = putfloat!(rsf.file,key,val)

"""
    putfloats!(rsf::_RSF,key::String,par::Array{Float32},n::Int)

    Write an array of float parameters to the RSF file represented by the `_RSF` struct. 
    The parameters are associated with the specified `key`.
"""
function putfloats!(rsf::_RSF,key::String,par::Array{T},n::Int) where T <: AbstractFloat
    if :none == rsf.dataname
        throw("putfloats to a closed file")
	end
    val = ""
    for i in 1:n-1
        val *= "$(par[i]),"
	end
    val *= "$(par[n])"
    enter!(rsf.pars, key, val)
end

putfloats!(rsf::Output,key::String,par::Array{T},n::Int) where T <: AbstractFloat = putfloats!(rsf.file,key,par,n)

"""
    getform(rsf::_RSF) -> String

    Return the data format of the RSF file represented by the `_RSF` struct.
"""
getform(rsf::_RSF) = rsf.form
getform(inp::Input) = getform(inp.file)
getform(out::Output) = getform(out.file)

"""
    setform!(rsf::_RSF, form::String)

    Set the data format of the RSF file represented by the `_RSF` struct to `form`. 
    If `form` is "ascii", it also sets the appropriate formats for ASCII output.
"""
function setform!(rsf::_RSF, form::String)
    rsf.form = form
    if form == "ascii"
        if :none != rsf.dataname
           putint!(rsf, "esize", 0) # for compatibility with SEPlib
		end
        rsf.aformat = :none
        rsf.eformat = :none
        rsf.aline = 8
	end
end

"""
    setformat!(rsf::_RSF, dataformat::String)

    Set the data type and format of the RSF file represented by the `_RSF` struct based on the provided `dataformat` string. 
    The function determines the appropriate data type and format (ASCII, XDR, or native) based on the contents of `dataformat`.
"""
function setformat!(rsf::_RSF, dataformat::String)
    done = false
	types = Dict("float" => Float32,
	    		 "int" => Int32,
				 "complex" => ComplexF32,
				 "uchar" => UInt8,
				 "char" => Int8,
				 "short" => Int16,
				 "long" => Int64,
				 "double" => Float64
				)
    for type in ("float", "int", "complex", "uchar", "short", "long", "double")
        if occursin(type, dataformat)
            settype!(rsf, types[type])
            done = true
            break
		end
	end
    if !done
        if occursin("byte", dataformat)
            settype!(rsf, types["uchar"])
        else
            settype!(rsf, types["char"])
		end
	end
    if dataformat[1:6] == "ascii_"
        setform!(rsf, "ascii")
	elseif dataformat[1:4] == "xdr_"
        setform!(rsf, "xdr")
    else
        setform!(rsf, "native")
	end
end

setformat!(rsf::Output, dataformat::String) = setformat!(rsf.file, dataformat)

"""
    getstring(rsf::_RSF, key::String, default=:none) -> String

    Retrieve the string value associated with the specified `key` in the RSF file represented by the `_RSF` struct.
    If the key is not found, return the `default` value.
"""
function getstring(rsf::_RSF, key::String, default=:none)
    get = getstring(rsf.pars, key)
    if get != :none
        return get
    else
        return default
	end
end

getstring(rsf::Input, key::String, default=:none) = getstring(rsf.file, key, default)
getstring(rsf::Output, key::String, default=:none) = getstring(rsf.file, key, default)

"""
    putstring!(rsf::_RSF, key::String, par::String)

    Write a string parameter to the RSF file represented by the `_RSF` struct. 
    The parameter is associated with the specified `key`.
"""
function putstring!(rsf::_RSF, key::String, par::String)
    if :none == rsf.dataname
        throw("putstring to a closed file")
	end
    val = "\"$(par)\""
    enter!(rsf.pars, key, val)
end

putstring!(rsf::Input, key::String, par::String) = putstring!(rsf.file, key, par)
putstring!(rsf::Output, key::String, par::String) = putstring!(rsf.file, key, par)

"""
    fileflush!(rsf::_RSF, src::_RSF)

    Flush the contents of the RSF file represented by the `_RSF` struct to disk. 
    If `src` is provided, it also flushes the contents of the source RSF file to the destination.
"""
function fileflush!(rsf::_RSF, src::Union{_RSF, Symbol})
    types = Dict(Float32 => "float",
	    		 Int32 => "int",
				 ComplexF32 => "complex",
				 UInt8 => "uchar",
				 Int8 => "char",
				 Int16 => "short",
				 Int64 => "long",
				 Float64 => "double"
				)
    if :none == rsf.dataname
        return
	end
    if :none != src && :none != src.head
        seek(src.head,0)
		for line in eachline(src.head)
			Base.write(rsf.stream, line * "\n")
		end
	end

    user = Libc.getuid()
	username = Libc.getpwuid(user).username
	now = Dates.now()
	time = Dates.format(now, "e, dd u yyyy HH:MM:SS")
	line = "$(getprog(par))\t$(pwd())\t$(username)\t$(gethostname())\t$(now)\n"
	Base.write(rsf.stream, line)

    putstring!(rsf, "data_format", join([rsf.form,types[rsf.type]],"_"))
    output(rsf.pars, rsf.stream)
    flush(rsf.stream)

    if rsf.dataname == "stdout"
        # keep stream, write the header end code
        Base.write(rsf.stream, "\tin=\"stdin\"\n\n\x0c\x0c\x04")
        flush(rsf.stream)
    else                 
        rsf.stream = open(rsf.dataname,"w+")
        rsf.dataname = :none
	end
end

"""
    fflush!(rsf::_RSF)

    Flush the contents of the RSF file represented by the `_RSF` struct to disk. 
"""
fflush!(rsf::_RSF) = flush(rsf.stream)

"""
    ucharwrite(rsf::_RSF, arr)

    Write an array of unsigned characters (UInt8) to the RSF file represented by the `_RSF` struct.
"""
function ucharwrite(rsf::_RSF, arr)
    if :none != rsf.dataname
        fileflush!(rsf, _infiles[1])
	end
	Base.write(rsf.stream, reinterpret(UInt8, arr))
end

"""
    intwrite(rsf::_RSF, arr)

    Write an array of integers (Int32) to the RSF file represented by the `_RSF` struct.
"""
function intwrite(rsf::_RSF,arr)
	if :none != rsf.dataname
        fileflush!(rsf, _infiles[1])
	end
                
    if rsf.form == "ascii"
        if rsf.aformat == :none
            aformat = Printf.Format("%d ")
        else
            aformat = rsf.aformat
		end
        if rsf.eformat == :none
            eformat = Printf.Format("%d ")
        else
            eformat = rsf.eformat
		end
        size = length(arr)
        farr = vec(arr)
        left = size    
        while left > 0
            nbuf = min(rsf.aline, left)
            last = size-left+nbuf
            for i in size-left+1:last-1
                Base.write(rsf.stream, Printf.format(aformat, farr[i]))
			end
			Base.write(rsf.stream, Printf.format(eformat, farr[last]))
            Base.write(rsf.stream, "\n")
            left -= nbuf
		end
    else
		Base.write(rsf.stream, reinterpret(UInt8, arr))
	end
end

"""
    floatwrite(rsf::_RSF, arr)

    Write an array of floats (Float32) to the RSF file represented by the `_RSF` struct.
"""
function floatwrite(rsf::_RSF,arr)
	if :none != rsf.dataname
        fileflush!(rsf, _infiles[1])
	end
                
    if rsf.form == "ascii"
        if rsf.aformat == :none
            aformat = Printf.Format("%g ")
        else
            aformat = rsf.aformat
		end
        if rsf.eformat == :none
            eformat = Printf.Format("%g ")
        else
            eformat = rsf.eformat
		end
        size = length(arr)
        farr = vec(arr)
        left = size    
        while left > 0
            nbuf = min(rsf.aline, left)
            last = size-left+nbuf
            for i in size-left+1:last-1
                Base.write(rsf.stream, Printf.format(aformat, farr[i]))
			end
			Base.write(rsf.stream, Printf.format(eformat, farr[last]))
            Base.write(rsf.stream, "\n")
            left -= nbuf
		end
    else
		Base.write(rsf.stream, reinterpret(UInt8, arr))
	end
end

"""
    intread!(rsf::_RSF, arr)  

    Read an array of integers (Int32) from the RSF file represented by the `_RSF` struct into the provided `arr`.
""" 
function intread!(rsf::_RSF, arr)
    if rsf.form == "ascii"
        size = length(arr)
        left = size    
        while left > 0
            line = readline(rsf.stream)
            row = readdlm(IOBuffer(line[1:end-1]), Int32)
            nbuf = min(length(row), left)
            arr[size-left+1:size-left+nbuf] .= row[1:nbuf]
            left -= nbuf
		end
    else
		bytes = Array{UInt8}(undef, length(arr)*4)
        readbytes!(rsf.stream, bytes)
		arr[:] = reinterpret(Int32, bytes)
	end
end

"""
    floatwrite(rsf::_RSF, arr)

    Write an array of floats (Float32) to the RSF file represented by the `_RSF` struct.
"""
function floatread!(rsf::_RSF, arr)
    if rsf.form == "ascii"
        arr[:] = readdlm(rsf.stream, Float32)
    else
		bytes = Array{UInt8}(undef, length(arr)*4)
        readbytes!(rsf.stream, bytes)
		arr[:] = reinterpret(Float32, bytes)
	end
end

"""
    dataread!(inp::Input, data::Array)

    Read data from the RSF file represented by the `Input` struct into the provided `data` array.
"""
function dataread!(inp::Input, data::Array)
	type = inp.file.type
	if type == Float32
        floatread!(inp.file, data)
	elseif type == Int32
		intread!(inp.file, data)
	else
        throw("Unsupported file type $(string(type))")
	end
end

"""
    datawrite(out::Output, data::Array)

    Write data from the provided `data` array to the RSF file represented by the `Output` struct.
"""
function datawrite(out::Output, data::Array)
	type = out.file.type
	if type == Float32
        floatwrite(out.file, data)
	elseif type == Int32
		intwrite(out.file, data)
	else
        throw("Unsupported file type $(string(type))")
	end
end

"""
    tell(rsf::_RSF) -> Int

    Return the current position in the RSF file represented by the `_RSF` struct.
"""
tell(rsf::_RSF) = position(rsf.stream)
tell(inp::Input) = tell(inp.file)
tell(out::Output) = tell(out.file)

"""
    bytes(rsf::_RSF) -> Int

    Return the size in bytes of the RSF file represented by the `_RSF` struct. 
    If the data name is "stdin", it returns -1. 
"""
function bytes(rsf::_RSF)
    if rsf.dataname == "stdin"
        return -1
	end
    if rsf.dataname == :none
        st = stat(rsf.stream)
	else
        st = stat(rsf.dataname)
	end
    return st.size
end

bytes(inp::Input) = bytes(inp.file)
bytes(out::Output) = bytes(out.file)

function getpar(file::_RSF, key::String, T::DataType, default=:none)
	get, par = getpar(file.pars, key, T)
	if get 
        return par
	else
        return default
	end
end

getint(inp::Input, key::String, default=:none) = getpar(inp.file, key, Int32, default)
getfloat(inp::Input, key::String, default=:none) = getpar(inp.file, key, Float32, default)

getint(out::Output, key::String, default=:none) = getpar(out.file, key, Int32, default)
getfloat(out::Output, key::String, default=:none) = getpar(out.file, key, Float32, default)

"""
    getshape(rsf::_RSF) -> Array{Int}

    Extract the shape of the data from the RSF file represented by the `_RSF` struct. 
    The function returns an array of integers representing the dimensions of the data.
"""
function getshape(rsf::_RSF)
    s = Array{Int}(undef, 0)
    dim = 1
    # check for n1, n2, ..., n9 parameters in the RSF file
    for i in 1:9
        ni = getpar(rsf, "n$i", Int)
        if ni != :none
            dim = i
            push!(s, ni)
        end
    end
    # remove trailing dimensions of size 1
    for i = dim:-1:1
        if s[i] <= 1
            pop!(s)
        else
            break
        end
    end
    return Tuple(s)
end

getshape(inp::Input) = getshape(inp.file)
getshape(out::Output) = getshape(out.file)

function fileclose(rsf::_RSF)
    if rsf.stream != :none && rsf.stream != stdin && rsf.stream != stdout
        flush(rsf.stream)
        Base.close(rsf.stream)
        rsf.stream = :none
    end
    if rsf.headname != :none
        rm(rsf.headname)
        rsf.headname = :none
    end
end

fileclose(out::Output) = fileclose(out.file)
fileclose(inp::Input) = fileclose(inp.file)