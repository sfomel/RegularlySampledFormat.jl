using Mmap

begin
	mutable struct RSF
        file::Input
        data::Array
        function RSF(tag::String)
            file = Input(tag)
            T = gettype(file)
            io = file.file.stream
            shape = getshape(file)
            dims = length(shape)
            data = Mmap.mmap(io, Array{T, dims}, shape)
            return new(file, data)
        end
    end
end

"""
    getshape(rsf)

    Extract the shape of the data array from the RSF file `rsf`.
"""
getshape(rsf::RSF) = size(rsf.data)