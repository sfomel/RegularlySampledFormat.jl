module RegularlySampledFormat

# Includes
include("SimTab.jl")
include("Par.jl")
include("RSF.jl")

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
       Temp 
       
end
