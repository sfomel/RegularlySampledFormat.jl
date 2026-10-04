begin
	# SimTab.jl:  A simple symbolic table for storing parameters
	struct SimTab 
		table::Dict{String,String}
	end
	SimTab() = SimTab(Dict{String,String}())
end

"""
    enter!(t, key, val)

	Enter a key-value pair into the symbolic table `t`.
"""
function enter!(t::SimTab, key::String, val::String) 
	t.table[key] = val
end

"""
	getpar(t, key, T)

	Extract a parameter of type `T` from the symbolic table `t` for a given `key`.
"""
function getpar(t::SimTab, key::String, T::DataType)
	val = get(t.table, key, false)
	if false == val
		return false, :none
	else
	        return true, parse(T, val)
	end
end

"""
	getpars(t, key, n, T)

	Extract an array of parameters from the symbolic table `t` for a given `key`. 
	The array will have length `n` and will be of type `T`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned.
"""
function getpars(t::SimTab, key::String, n::Int, T::DataType)
	val = get(t.table, key, false)
	if false == val
		return false, :none
	else
		vals = split(val,",")
        	nval = length(vals)
        	# set array to length n
        	if n < nval
            	   vals = vals[1:n]
			elseif n > nval
	    	   vals = vcat(vals, repeat([vals[nval]], n-nval))
			end
		return true, [parse(T, v) for v in vals]
	end
end

"""
	add!(t, keyval)

	Enter a key-value pair into the symbolic table `t` from a string of the form "key=val".
"""
function add!(t::SimTab, keyval::String)
    if '=' in keyval
        key, val = split(keyval, '=')
        enter!(t, String(key), String(val))
    end
end

"""
	string!(t, string)

	Enter key-value pairs into the symbolic table `t` from a string of the form "key1=val1 key2=val2 ...".
"""
function string!(t::SimTab, string::String)
    for word in split(string)
	add!(t, String(word))
    end
end

"""
	output(t, filep)

	Output the contents of the symbolic table `t` to a file stream `filep`.
"""
function output(t::SimTab, filep::IOStream)
    for key in keys(t.table)
        Base.write(filep, "\t$(key)=$(t.table[key])\n")
	end
end

"""
	input!(t, filep)

	Input key-value pairs into the symbolic table `t` from a file stream `filep`.
"""
function input!(t::SimTab, filep::IOStream, out=:none)
    # Special code b'\x0c\x0c\x04', if encountered, signifies
    # the end of the header and the start of the data.
    # With each new line, we will try to read the first three
    # bytes and compare them to the code before reading the
    # rest of the line.
    while true
        try
            line3 = read(filep, 3)
            # skip new lines
            while line3[1] == 0x0a
                line3 = vcat(line3[2:end], read(filep, 1))
	    	end
            # check code for the header end
            if line3[1] == 0x0c && line3[2] == 0x0c && line3[3] == 0x04
                break
	    	end
            line = String(line3) * readline(filep)
            if length(line) < 1
                break
	    	end
            # extract parameters
            string!(t, line)
			if out != :none
            	Base.write(out, line)
	    	end
        catch
            break
        end
    end
    if out != :none
        flush(out)
    end
end

"""
	getstring(t, key)

	Extract a string parameter from the symbolic table `t` for a given `key`.
"""
function getstring(t::SimTab, key::String)
	val = get(t.table, key, false)
	if false == val
		return :none
	else
		# strip quotes
        if val[1] == '"' && val[end] == '"'
            val = val[2:end-1]
		end
        return val
	end
end

"""
	getbool(t, key)

	Extract a boolean parameter from the symbolic table `t` for a given `key`.
"""
function getbool(t::SimTab, key::String)
	val = get(t.table, key, false)
	if false == val
		return false, :none
	else
		if val[1] == 'y' || val[1] == 'Y' || val[1] == '1'
            return true, true
        else
            return true, false
		end
	end
end

"""
	getbools(t, key, n)

	Extract an array of boolean parameters from the symbolic table `t` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned.
"""
function getbools(t::SimTab, key::String, n::Int)
	val = get(t.table, key, false)
	if false == val
		return false, :none
	else
		vals = split(val,",")
        nval = length(vals)
        # set array to length n
        if n < nval
            vals = vals[1:n]
		elseif n > nval
			vals = vcat(vals, repeat([vals[nval]], n-nval))
		end
		bools = [v[1] == 'y' || v[1] == 'Y' || v[1] == '1' for v in vals]
        return true, bools
	end
end

"""
	getint(t, key)

	Extract an integer parameter from the symbolic table `t` for a given `key`.
"""
getint(t::SimTab, key::String) = getpar(t, key, Int32)

"""
	getints(t, key, n)

	Extract an array of integer parameters from the symbolic table `t` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned.
"""
getints(t::SimTab, key::String, n::Int) = getpars(t, key, n, Int32)

"""
	getfloat(t, key)

	Extract a float parameter from the symbolic table `t` for a given `key`.
"""
getfloat(t::SimTab, key::String) = getpar(t, key, Float32)

"""
	getfloats(t, key, n)

	Extract an array of float parameters from the symbolic table `t` for a given `key`. 
	The array will have length `n`. If the number of values in the table is less than `n`, the last value will be repeated to fill the array. If the number of values is greater than `n`, only the first `n` values will be returned.
"""
getfloats(t::SimTab, key::String, n::Int) = getpars(t, key, n, Float32)