# This file contains the main functions for reading and writing RSF files, 
# as well as some utility functions for handling RSF data.

using Printf

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
			re = "(?:$(Base.Libc.gethostname())\\s+)?datapath=(\\S+)" 
            for line in readlines(pathfile)
				check = match(re, line)
                if check != nothing
                    path = check.captures(2)
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
        for f in readdir(".")
            # Comparing the unique file ID stored by the OS for the file stream
            # with the known entries in the file table:
            if isfile(f) && inode == stat(f).inode
                found_stdout = true
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
		stream::IOStream
		pars::SimTab
		headname::String
		head::IOStream
		dataname::String
		pipe::Bool
		type::DataType
		form::String
        aformat::Printf.Format
        eformat::Printf.Format
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
			new = _RSF(stream, pars, headname, head, dataname, false, Float32, "native", Printf.Format(""), Printf.Format(""), 8)
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
		else
			if tag==nothing || tag=="out"
				stream = stdout
				filename = :none
			else
				if filename == :none
					filename = tag
				end
				stream = open(filename,"w+")
			end
			# try piping
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
	Input(tag::String) = Input(_RSF(true,tag))
end

begin
	mutable struct Output
		file::_RSF
	end
	Output(tag::String) = Output(_RSF(false,tag))
end

"""
    gettype(rsf::_RSF) -> DataType

    Return the data type of the RSF file represented by the `_RSF` struct.
"""
gettype(rsf::_RSF) = rsf.type

"""
    settype!(rsf::_RSF, T::DataType)

    Set the data type of the RSF file represented by the `_RSF` struct to `T`.
"""
function settype!(rsf::_RSF, T::DataType)
	rsf.type = T
end

"""
    putint!(rsf::_RSF, key::String, par::Int)

    Write an integer parameter to the RSF file represented by the `_RSF` struct. 
    The parameter is associated with the specified `key`.
"""
function putint!(rsf::_RSF, key::String, par::Int)
    if :none == rsf.dataname
        throw("putint to a closed file")
	end
    val = "$par"
    enter!(rsf.pars, key, val)
end

"""
    putfloat!(rsf::_RSF, key::String, par::Float)

    Write a float parameter to the RSF file represented by the `_RSF` struct. 
    The parameter is associated with the specified `key`.
"""
function putints!(rsf::_RSF,key::String,par::Array{Int},n::Int)
    if :one == rsf.dataname
        throw("putints to a closed file")
	end
    val = ""
    for i in 1:n-1
        val *= "$(par[i]),"
	end
    val *= "$(par[n])"
    enter!(rsf.pars, key, val)
end

"""
    putfloats!(rsf::_RSF,key::String,par::Array{Float32},n::Int)

    Write an array of float parameters to the RSF file represented by the `_RSF` struct. 
    The parameters are associated with the specified `key`.
"""
function putfloat!(rsf::_RSF, key::String, par::Float32)
    if :none == rsf.dataname
        throw("putint to a closed file")
	end
    val = "$par"
    enter!(rsf.pars, key, val)
end

"""
    putfloats!(rsf::_RSF,key::String,par::Array{Float32},n::Int)

    Write an array of float parameters to the RSF file represented by the `_RSF` struct. 
    The parameters are associated with the specified `key`.
"""
function putfloats!(rsf::_RSF,key::String,par::Array{Float32},n::Int)
    if :one == rsf.dataname
        throw("putints to a closed file")
	end
    val = ""
    for i in 1:n-1
        val *= "$(par[i]),"
	end
    val *= "$(par[n])"
    enter!(rsf.pars, key, val)
end

"""
    getform(rsf::_RSF) -> String

    Return the data format of the RSF file represented by the `_RSF` struct.
"""
getform(rsf::_RSF) = rsf.form

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
        rsf.aformat = Printf.Format("")
        rsf.eformat = Printf.Format("")
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

"""
    fileflush!(rsf::_RSF, src::_RSF)

    Flush the contents of the RSF file represented by the `_RSF` struct to disk. 
    If `src` is provided, it also flushes the contents of the source RSF file to the destination.
"""
function fileflush!(rsf::_RSF, src::_RSF)
    if :none == rsf.dataname
        return
	end
    if :none != src && :none != src.head
        seek(src.head,0)
		for line in eachline(src.head)
			write(line, rsf.stream)
		end
	end

    user = Libc.getuid()
	username = Libc.getpwuid(user).username
	now = Dates.now()
	time = Dates.format(now, "e, dd u yyyy HH:MM:SS")
	line = "$(getprog(par))\t$(pwd())\t$(username)\t$(gethostname())\t$(now)\n"
	write(line, rsf.stream)

    putstring!(rsf, "data_format", join([rsf.form,rsf.type],"-"))
    output(rsf.pars, rsf.stream)
    flush(rsf.stream)

    if rsf.dataname == "stdout"
        # keep stream, write the header end code
        write(rsf.stream, "\tin=\"stdin\"\n\n\x0c\x0c\x04")
        flush(rsf.stream)
    else                 
        rsf.stream = open(rsf.dataname,"w+b")
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
	write(rsf.stream, reinterpret(UInt8, arr))
end

"""
    intwrite(rsf::_RSF, arr)

    Write an array of integers (Int32) to the RSF file represented by the `_RSF` struct.
"""
function intwrite(rsf::_RSF,arr)
	if :none != rsf.dataname
        fileflush!(rsf, _infiles[1])
	end
                
    if self.form == "ascii"
        if rsf.aformat == Printf.Format("")
            aformat = Printf.Format("%d ")
        else
            aformat = rsf.aformat
		end
        if self.eformat == Printf.Format("")
            eformat = Printf.Format("%d ")
        else
            eformat = rsf.eformat
		end
        size = length(arr)
        farr = vec(arr)
        left = size    
        while left > 0
            nbuf = min(self.aline, left)
            last = size-left+nbuf
            for i in size-left+1:last-1
                write(self.stream, Printf.format(aformat, farr[i]))
			end
			write(self.stream, Printf.format(eformat, farr[last]))
            write(self.stream, "\n")
            left -= nbuf
		end
    else
		write(rsf.stream, reinterpret(UInt8, arr))
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
                
    if self.form == "ascii"
        if rsf.aformat == Printf.Format("")
            aformat = Printf.Format("%g ")
        else
            aformat = rsf.aformat
		end
        if self.eformat == Printf.Format("")
            eformat = Printf.Format("%g ")
        else
            eformat = rsf.eformat
		end
        size = length(arr)
        farr = vec(arr)
        left = size    
        while left > 0
            nbuf = min(self.aline, left)
            last = size-left+nbuf
            for i in size-left+1:last-1
                write(self.stream, Printf.format(aformat, farr[i]))
			end
			write(self.stream, Printf.format(eformat, farr[last]))
            write(self.stream, "\n")
            left -= nbuf
		end
    else
		write(rsf.stream, reinterpret(UInt8, arr))
	end
end

"""
    intread!(rsf::_RSF, arr)  

    Read an array of integers (Int32) from the RSF file represented by the `_RSF` struct into the provided `arr`.
""" 
function intread!(rsf::_RSF, arr)
    if rsf.form == "ascii"
        arr[:] = readdlm(rsf.stream, Int32)
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
    read!(inp::Input, data::Array)

    Read data from the RSF file represented by the `Input` struct into the provided `data` array.
"""
function read!(inp::Input, data::Array)
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
    write(out::Output, data::Array)

    Write data from the provided `data` array to the RSF file represented by the `Output` struct.
"""
function write(out::Output, data::Array)
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
