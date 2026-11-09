module RegularlySampledFormat

# RegularlySampledFormat.jl: A Julia module for handling regularly sampled data format (RSF files).
# This module provides functionality for reading, writing, and manipulating RSF files in Julia.

# Ignore SIGPIPE signals to prevent programs from terminating when writing to a closed pipe.
ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 13, C_NULL)  # SIGPIPE = 13, SIG_DFL = NULL

# Includes
include("SimTab.jl")
include("Par.jl")
include("RSF.jl")
include("IO.jl")
include("File.jl")

"""
    __init__()

	Initialize the RegularlySampledFormat module. This function is called automatically when the module is loaded.
"""
function __init__()
        # Runs at load time in every session that uses the package
    global _par, _infiles
    # parameters and input files initialization
    _par = Par()
    _infiles = Vector{Union{_RSF, Symbol}}(undef, 1)
    _infiles[1] = :none
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 13, C_NULL)  # e.g. restore default SIGPIPE
end

# Exports
export getint,
       getstring,
       getints,
       getfloat,
       getfloats,
       getbool,
       getbools,
       output,
       Par,
       _par,
       getprog,
       Datapath,
       Temp,
       setformat!,
       gettype,
       settype!,
       getform,   
       setform!,
       putint!,
       putints!,  
       putfloat!,
       putfloats!,
       putstring!,
       tell,
       bytes,
       Input,
       Output,
       RSF,
       getshape,
       fileclose,
       getfilename,
       datawrite,
       dataread!,
       flush!,
       setaformat!,
       leftsize,
       fileflush!
end
