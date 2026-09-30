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

"""
	getprog(p)

	Extract the program name from the parameter table `p`.
"""
getprog(p::Par) = p.prog

"""
	getpar(p, key, T, default)

	Extract a parameter of type `T` from the parameter table `p` for a given `key`. 
	If the key is not found, return the `default` value.
"""
function getpar(p::Par, key::String, T::DataType, default=:none)
	get, par = getpar(p.pars, key, T)
	if get 
        return par
	else
        return default
	end
end

"""
	getint(key, default)

	Extract an integer parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getint(key::String, default=:none) = getpar(par, key, Int32, default)

"""
	getfloat(key, default)

	Extract a float parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getfloat(key::String, default=:none) = getpar(par, key, Float32, default)

"""
	getbool(key, default)

	Extract a boolean parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getbool(key::String, default=:none) = getpar(par, key, Bool, default)

"""
	getstring(key, default)

	Extract a string parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getstring(key::String, default=:none) = getpar(par, key, String, default)

"""
	getpars(p, key, n, T, default)

	Extract an array of parameters of type `T` from the parameter table `p` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
function getpars(p::Par, key::String, n::Int, T::DataType, default=:none)
	get, pars = getpars(p.pars, key, n, T)
	if get == false	&& default != :none 
		nval = length(default)
        # set array to length n
        if n < nval
            pars = default[1:n]
		elseif n > nval
	    	pars = vcat(default, repeat([default[nval]], n-nval))
		else
			pars = default
		end
	end
	return pars
end

"""
	getints(key, n, default)

	Extract an array of integer parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getints(key::String, n::Int, default=:none) = getpars(par, key, n, Int32, default)

"""
	getfloats(key, n, default)

	Extract an array of float parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""		
getfloats(key::String, n::Int, default=:none) = getpars(par, key, n, Float32, default)

"""
	getbools(key, n, default)

	Extract an array of boolean parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getbools(key::String, n::Int, default=:none) = getpars(par, key, n, Bool, default)
