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
	_infiles = Vector{_RSF}(undef, 1)
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
			# keep track of input files
			new = _RSF(stream, pars, headname, head, dataname, false, Float32, "native", Printf.Format(""), Printf.Format(""), 8)
			if filename == :none
				_infiles[1] = new
			else
				push!(_infiles, new)
			end
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
			return _RSF(stream, SimTab(), :none, :none, dataname, pipe, Float32, "native", :none, :none, 8)
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
