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

abstract type AbstractRSF end

begin
	mutable struct Input <: AbstractRSF
		file::_RSF
	end
    """
    Input(tag::String) -> Input

    Create an instance of the `Input` struct for reading from an RSF file specified by `tag`.
    """
	Input(tag::String) = Input(_RSF(true,tag))
end

begin
	mutable struct Output <: AbstractRSF
		file::_RSF
	end
    """
    Output(tag::String) -> Output

    Create an instance of the `Output` struct for writing to an RSF file specified by `tag`.    
    """
	Output(tag::String) = Output(_RSF(false,tag))
end

"""
    gettype(inp::AbstractRSF) -> DataType

    Return the data type of the RSF file represented by the `AbstractRSF` struct.
"""
gettype(inp::AbstractRSF) = gettype(inp.file)

"""
    setform!(rsf::AbstractRSF, form::String)

    Set the data format of the RSF file represented by the `AbstractRSF` struct to `form`.
"""
setform!(rsf::AbstractRSF, form::String) = setform!(rsf.file, form)

"""
    settype!(rsf::AbstractRSF, T::DataType)

    Set the data type of the RSF file represented by the `AbstractRSF` struct to `T`.
"""
settype!(rsf::AbstractRSF, T::DataType) = settype!(rsf.file, T)  

"""
    putint!(rsf::Output, key::String, par::Integer)

    Write an integer parameter to the RSF file represented by the `Output` struct. 
    The parameter is associated with the specified `key`.
"""
putint!(rsf::Output, key::String, par::Integer) = putint!(rsf.file, key, par)

""" 
    putints!(rsf::Output, key::String, par::Array{<:Integer}, n::Int)

    Write an array of integer parameters to the RSF file represented by the `Output` struct.
    The parameters are associated with the specified `key`. The array has length `n`.
"""
putints!(rsf::Output,key::String,par::Array{<:Integer},n::Int) = putints!(rsf.file,key,par,n)

"""
    putfloat!(rsf::Output, key::String, val::AbstractFloat)

    Write a float parameter to the RSF file represented by the `Output` struct. 
    The parameter is associated with the specified `key`.
""" 
putfloat!(rsf::Output,key::String,val::AbstractFloat) = putfloat!(rsf.file,key,val)

"""
    putfloats!(rsf::Output, key::String, par::Array{<: AbstractFloat}, n::Int)

    Write an array of float parameters to the RSF file represented by the `Output` struct. 
    The parameters are associated with the specified `key`. The array has length `n`.
"""
putfloats!(rsf::Output,key::String,par::Array{<: AbstractFloat},n::Int) = putfloats!(rsf.file,key,par,n)

"""
    getform(inp::AbstractRSF) -> String

    Return the data format of the RSF file represented by the `AbstractRSF` struct.
"""
getform(inp::AbstractRSF) = getform(inp.file)

"""
    setformat!(rsf::Output, dataformat::String)

    Set the data type and format of the RSF file represented by the `Output` struct based on the provided `dataformat` string. 
    The function determines the appropriate data type and format (ASCII, XDR, or native) based on the contents of `dataformat`.
"""
setformat!(rsf::Output, dataformat::String) = setformat!(rsf.file, dataformat)

"""
    getstring(rsf::AbstractRSF, key::String, default=:none) -> String

    Retrieve the string value associated with the specified `key` in the RSF file represented by the `AbstractRSF` struct.
    If the key is not found, return the `default` value.
"""
getstring(rsf::AbstractRSF, key::String, default=:none) = getstring(rsf.file, key, default)

"""
    putstring!(rsf::Output, key::String, par::String)

    Write a string parameter to the RSF file represented by the `Output` struct. 
    The parameter is associated with the specified `key`.
"""
putstring!(rsf::Output, key::String, par::String) = putstring!(rsf.file, key, par)

"""
    flush!(out::Output)

    Flush the contents of the RSF file represented by the `Output` struct to disk. 
"""
flush!(out::Output) = flush!(out.file)

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
    elseif type == UInt8
        ucharread!(inp.file, data)
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
    elseif type == UInt8
        ucharwrite(out.file, data)
	else
        throw("Unsupported file type $(string(type))")
	end
end

"""
    tell(inp::AbstractRSF) -> Int

    Return the current position in the RSF file represented by the `AbstractRSF` struct.
"""
tell(inp::AbstractRSF) = tell(inp.file)

"""
    bytes(rsf::AbstractRSF) -> Int

    Return the size in bytes of the RSF file represented by the `AbstractRSF` struct. 
""" 
bytes(inp::AbstractRSF) = bytes(inp.file)

"""
    getint(inp::AbstractRSF, key::String, default=:none) -> Int

    Get an integer parameter from the RSF file represented by the `AbstractRSF` struct.
"""
getint(inp::AbstractRSF, key::String, default=:none) = getpar(inp.file, key, Int32, default)

"""
    getfloat(rsf::AbstractRSF, key::String, default=:none) -> Float

    Get a float parameter from the RSF file represented by the `AbstractRSF` struct.
"""
getfloat(rsf::AbstractRSF, key::String, default=:none) = getpar(rsf.file, key, Float32, default)

"""
    getshape(rsf::AbstractRSF) -> Tuple{Vararg{Int}}

    Extract the shape of the data from the RSF file represented by the `AbstractRSF` struct. 
    The function returns a tuple of integers representing the dimensions of the data.
"""
getshape(inp::AbstractRSF) = getshape(inp.file)

"""
    setaformat!(out::Output, format::String, line::Int=8, strip::Int=0)

    Set the ASCII format for the RSF file represented by the `Output` struct.
"""
setaformat!(out::Output, format::String, line::Int=8, strip::Int=0) = setaformat!(out.file, format, line, strip)

"""
    fileclose(rsf::AbstractRSF)

    Close the RSF file represented by the `AbstractRSF` struct.
"""
fileclose(rsf::AbstractRSF) = fileclose(rsf.file)

"""
    leftsize(rsf::AbstractRSF, dim::Int) -> Int

    Return the product of the sizes of the dimensions following the specified dimension `dim` in the RSF file represented by the `Output` struct.
"""
leftsize(inp::AbstractRSF, dim::Int) = leftsize(inp.file, dim)

"""
    fileflush!(out::Output, src::Union{_RSF, Symbol})

    Flush the contents of the RSF file represented by the `Output` struct to disk. 
    If `src` is provided, it also flushes the contents of the source RSF file to the destination.
"""
fileflush!(out::Output, src::Union{_RSF, Symbol}) = fileflush!(out.file, src)