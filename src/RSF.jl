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
			re = "(?:$(Sys.gethostname())\\s+)?datapath=(\\S+)" 
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
			head = open(headname, "w+")
			# read parameters
			pars = SimTab()
			input!(pars, stream, head)
			# get dataname
            filename = getstring(pars,"in")
            if filename == :none
				throw("No in= in file \"$tag\" ")
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






