# This file contains the main functions for reading and writing RSF files, 
# as well as some utility functions for handling RSF data.

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

