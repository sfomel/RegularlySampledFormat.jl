# RegularlySampledFormat

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sfomel.github.io/RegularlySampledFormat.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sfomel.github.io/RegularlySampledFormat.jl/dev/)
[![Build Status](https://github.com/sfomel/RegularlySampledFormat.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/sfomel/RegularlySampledFormat.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/sfomel/RegularlySampledFormat.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/sfomel/RegularlySampledFormat.jl)

The [RegularlySampledFormat](https://github.com/sfomel/RegularlySampledFormat.jl) package provides an interface for working with RSF files.

<img src=https://ahay.org/wikilocal/style/Madagascar2.png>

The **RSF** file format is used in the [Madagascar](https://en.wikipedia.org/wiki/Madagascar_(software)) open-source package for geophysical data analysis.

## Installation

RegularlySampledFormat.jl requires Julia 1.10.10 or later. From the Julia REPL, press `]` to enter package mode and run:

```Julia
pkg> add https://github.com/sfomel/RegularlySampledFormat.jl
```

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

## Documentation

[API Reference](https://sfomel.github.io/RegularlySampledFormat.jl/stable/)

## API Reference

- [**Stable**](https://sfomel.github.io/RegularlySampledFormat.jl/stable/): docs for the latest release
- [**Dev**](https://sfomel.github.io/RegularlySampledFormat.jl/dev/): docs for the main branch