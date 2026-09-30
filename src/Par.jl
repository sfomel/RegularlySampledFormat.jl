begin
	# Par.jl:  A simple parameter table for storing parameters
	struct Par 
		pars::SimTab
		prog::String
	end
	function Par(progfile, args::Vector{String})
		prog = progfile
		pars = SimTab()
		for arg in args
			if length(arg) > 4 && arg[1:4] == "par="
                # extract parameters from parameter file
                parfile = open(arg[5:end])
                input!(pars, parfile)
                close(parfile)
            else
                add!(pars, arg)
			end
		end
		return Par(pars, prog)
	end
	Par() = Par(PROGRAM_FILE, ARGS)
	par = Par("julia",["-"])
end

getprog(p::Par) = p.prog

function getpar(p::Par, key::String, T::DataType, default=:none)
	get, par = getpar(p.pars, key, T)
	if get 
        return par
	else
        return default
	end
end

getint(key::String, default=:none) = getpar(par, key, Int32, default)
getfloat(key::String, default=:none) = getpar(par, key, Float32, default)
getbool(key::String, default=:none) = getpar(par, key, Bool, default)
getstring(key::String, default=:none) = getpar(par, key, String, default)

