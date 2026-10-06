module RegularlySampledFormat

# Includes
include("SimTab.jl")
include("Par.jl")
include("RSF.jl")
include("File.jl")

# Exports
export SimTab,
       enter!,
       add!,
       string!,
       input!,
       getint,
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
       gettype,
       settype!,
       getform,   
       setform!,
       putint!,
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
       dataread!

end
