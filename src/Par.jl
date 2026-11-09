begin
	# Par.jl:  A simple parameter table for storing parameters
	struct Par 
		pars::SimTab
		prog::String
	end
	"""
	Par(progfile::String, args::Vector{String})

	Create a new parameter table from the given program file and arguments.
	"""
	function Par(progfile::String, args::Vector{String})
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
	"""
	Par()

	Create a new parameter table from the default program file and arguments.
	"""
	Par() = Par(PROGRAM_FILE, ARGS)
end

"""
	getprog()

	Extract the running program name
"""
getprog(par::Par) = par.prog
getprog() = _par.prog
"""
	getpar(p, key, T, default)

	Extract a parameter of type `T` from the parameter table `p` for a given `key`. 
	If the key is not found, return the `default` value.
"""
function getpar(p::Par, key::String, T::DataType, default=:none)
	get, val = getpar(p.pars, key, T)
	if get 
        return val
	else
        return default
	end
end

"""
	Extract a parameter of type `T` from the default parameter table `_par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getpar(key::String, T::DataType, default=:none) = getpar(_par, key, T, default)

"""
	getint(par, key, default)

	Extract an integer parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getint(par::Par, key::String, default=:none) = getpar(par, key, Int32, default)

"""
	getfloat(key, default)

	Extract a float parameter from the default parameter table `_par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getfloat(key::String, default=:none) = getpar(_par, key, Float32, default)	

"""
	getint(key, default)

	Extract an integer parameter from the default parameter table `_par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getint(key::String, default=:none) = getpar(_par, key, Int32, default)

"""
	getfloat(par, key, default)

	Extract a float parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getfloat(par::Par, key::String, default=:none) = getpar(par, key, Float32, default)

"""
	getbool(par, key, default)

	Extract a boolean parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
function getbool(par::Par, key::String, default=:none) 
	get, val = getbool(par.pars, key)
	if get 
        return val
	else
        return default
	end
end

"""
	Extract a boolean parameter from the default parameter table `_par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getbool(key::String, default=:none) = getbool(_par, key, default)

"""
	getstring(par, key, default)

	Extract a string parameter from the parameter table `par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
function getstring(par::Par, key::String, default=:none)
	val = getstring(par.pars, key)
	if val != :none
        return val
	else
        return default
	end
end

"""
	getstring(key, default)

	Extract a string parameter from the default parameter table `_par` for a given `key`. 
	If the key is not found, return the `default` value.
"""
getstring(key::String, default=:none) = getstring(_par, key, default)	

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
	getpars(key, n, T, default)

	Extract an array of parameters of type `T` from the default parameter table `_par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getpars(key::String, n::Int, T::DataType, default=:none) = getpars(_par, key, n, T, default)

"""
	getints(par, key, n, default)

	Extract an array of integer parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getints(par::Par, key::String, n::Int, default=:none) = getpars(par, key, n, Int32, default)

"""
	getints(key, n, default)

	Extract an array of integer parameters from the default parameter table `_par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getints(key::String, n::Int, default=:none) = getints(_par, key, n, default)

"""
	getfloats(par, key, n, default)

	Extract an array of float parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""		
getfloats(par::Par, key::String, n::Int, default=:none) = getpars(par, key, n, Float32, default)

"""
	getfloats(key, n, default)

	Extract an array of float parameters from the default parameter table `_par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getfloats(key::String, n::Int, default=:none) = getfloats(_par, key, n, default)

"""
	getbools(par, key, n, default)

	Extract an array of boolean parameters from the parameter table `par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
function getbools(par::Par, key::String, n::Int, default=:none)
	get, pars = getbools(par.pars, key, n)
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
	getbools(key, n, default)

	Extract an array of boolean parameters from the default parameter table `_par` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned. If the key is not found, return the `default` value.
"""
getbools(key::String, n::Int, default=:none) = getbools(_par, key, n, default)