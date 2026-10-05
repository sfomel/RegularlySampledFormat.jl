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
        function RSF(data::Array, name::String="")
            type = eltype(data)
            if type == Float32
                dformat = "native_float"
            elseif type == Int32
                dformat = "native_int"
            elseif type == UInt8
                dformat = "native_uchar"
            else
                error("Unsupported data type: $type")
            end
            if name == ""
                name = Temp()
            end
            file = Output(name)
            setformat!(file, dformat)
            shape = size(data)
            dims = length(shape)
            for axis in 1:dims
                putint!(file, "n$axis", shape[axis])
            end
            write(file, data)
            fileclose(file)
            return RSF(name)
        end
    end
end

"""
    getshape(rsf)

    Extract the shape of the data array from the RSF file `rsf`.
"""
getshape(rsf::RSF) = size(rsf.data)