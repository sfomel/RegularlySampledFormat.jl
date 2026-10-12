```@meta
CurrentModule = RegularlySampledFormat
```

# RegularlySampledFormat

The [RegularlySampledFormat](https://github.com/sfomel/RegularlySampledFormat.jl) package provides an interface for working with RSF files.

<img src=https://ahay.org/wikilocal/style/Madagascar2.png>

The **RSF** file format is used in the [Madagascar](https://ahay.org/) open-source package for geophysical data analysis.

The format is documented in the [Madagascar documentation](https://ahay.org/wiki/Guide_to_RSF_file_format).

## Quick examples

### Working with an existing RSF file

```julia
using RegularlySampledFormat

file = RSF("file.rsf");
data = file.data # a multi-dimensional Julia array
```

### Creating an RSF file out of a multidimensional array

```julia
data = ones(Float32, 5, 2);
file = RSF(data, "file.rsf")
```

### Open an RSF file for reading

```julia
inp = Input("file.rsf")
n1 = getint(inp,"n1")
T = gettype(inp)
trace = Array{T}(undef, n1)
dataread!(inp, trace)
fileclose(inp)
```

### Open an RSF file for writing

```julia
out = Output("file.rsf")
putint!(out, "n1", 10)
setformat!(out,"native_int")
data = ones(Float32, 10)
datawrite(out, data)
fileclose(out)
```

```@index
```

```@autodocs
Modules = [RegularlySampledFormat]
Pages = ["File.jl", "Par.jl"]
```
