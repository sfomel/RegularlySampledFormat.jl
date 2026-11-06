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
       leftsize
end
