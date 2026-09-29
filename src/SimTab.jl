begin
	# emulate api/c/simtab.c
	struct SimTab 
		table::Dict{String,String}
	end
	SimTab() = SimTab(Dict{String,String}())
end

function enter!(t::SimTab, key::String, val::String) 
	t.table[key] = val
end

function getpar(t::SimTab, key::String, T::DataType)
	val = get(t.table, key, false)
	if false == val
		return false, :none
	else
	        return true, parse(T, val)
	end
end

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

function put!(t::SimTab, keyval::String)
    if '=' in keyval
        key, val = split(keyval, '=')
        enter!(t, String(key), String(val))
    end
end

function string!(t::SimTab, string::String)
    for word in split(string)
	put!(t, String(word))
    end
end

# extract parameters from header file
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
            while line3[:1] == '\n'
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
            if out != :none
                write(out, line)
	    end
            # extract parameters
            string!(t, line)
       catch
            break
        end
    end
    if out != :none
        flush(out)
    end
end

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

getint(t::SimTab, key::String) = getpar(t, key, Int32)
getints(t::SimTab, key::String, n::Int) = getpars(t, key, n, Int32)

getfloat(t::SimTab, key::String) = getpar(t, key, Float32)
getfloats(t::SimTab, key::String, n::Int) = getpars(t, key, n, Float32)