begin
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

