using Mmap

begin
	mutable struct RSF
        file::Input
        data::Array
        """
            RSF(tag::String)
            RSF(data::Array, name::String="")

            Constructors for the RSF type.
        """
        function RSF(tag::String)
            file = Input(tag)
            T = gettype(file)
            io = file.file.stream
            shape = getshape(file)
            dims = length(shape)
            form = getform(file)
            if form == "native"
                data = Mmap.mmap(io, Array{T, dims}, shape)
            elseif form == "xdr"
                bshape = collect(shape)
                if T == Int32  || T == Float32
                    bshape[1] *= 4
                    bytes = Mmap.mmap(io, Array{UInt8, dims}, Tuple(bshape))
                    bytes .= reinterpret(UInt8, ntoh.(reinterpret(UInt32, bytes)))
                    data = reinterpret(T, bytes)
                else
                    error("Unsupported type for xdr form: $T")
                end
            else
                error("Unsupported form: $form")
            end
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
            datawrite(file, data)
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