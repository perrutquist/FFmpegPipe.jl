module FFmpegPipe

using Images
using FileIO
using ImageMagick # alternatively: QuartsImageIO

export openvideo, readframe, writeframe

const ffmpeg = "ffmpeg" # name of executable

"""
Open a movie file using ffmpeg's image2pipe interface.
"""
openvideo(filename::String; kwargs...) = openvideo(filename, :r; kwargs...)
openvideo(filename::String, mode::Symbol; kwargs...) = openvideo(filename, Val{mode}(); kwargs...)
openvideo(filename::String, mode::Union{Char,String}; kwargs...) = openvideo(filename, Symbol(mode); kwargs...)

function addkwargs!(input_options, output_options, kwargs)
    for (namein, value) in kwargs
        m = match(r"^(.*)_(in|out)", string(namein))
        if m ≢ nothing 
            name, direction = m.captures
            if direction == "in"
                input_options[Symbol(name)] = value
            else
                output_options[Symbol(name)] = value
            end
        else
            output_options[namein] = value
        end
    end
end

"""
`openvideo(file, :r)` opens movie file for reading
"""

function openvideo(filename::String, ::Val{:r}; loglevel_out = "fatal", kwargs...)
    input_options = Dict{Symbol, Any}()
    output_options = Dict{Symbol, Any}(:loglevel => loglevel_out)
    addkwargs!(input_options, output_options, kwargs)
    before = Iterators.flatten(("-$k", v) for (k,v) in pairs(input_options))
    after = Iterators.flatten(("-$k", v) for (k,v) in pairs(output_options))
    cmd = `$ffmpeg -nostats $before -i $filename $after -f image2pipe -vcodec png -compression_level 0 -`
    open(cmd)
end

"""
`openvideo(file, :w)` opens movie file for writing
"""
function openvideo(filename::String, ::Val{:w}; r_out=24, q_out=3, vcodec_out="h264", loglevel_out="fatal", kwargs...)
    input_options = Dict{Symbol, Any}()
    output_options = Dict{Symbol, Any}(:r => r_out, :q => q_out, :vcodec => vcodec_out, :loglevel => loglevel_out)
    addkwargs!(input_options, output_options, kwargs)
    before = Iterators.flatten(("-$k", v) for (k,v) in input_options)
    after = Iterators.flatten(("-$k", v) for (k,v) in output_options)
    cmd = `$ffmpeg -nostats -f image2pipe -vcodec png $before -i - $after $filename`
    open(cmd, "w")
end

function openvideo(f::Function, filename::String, mode; kwargs...)
    io = openvideo(filename, mode; kwargs...)
    try
        f(io)
    finally
        close(io)
    end
end

# Read up to the end of a .png image, one chunk at a time,
# while parsing for the "IEND" chunk.
# (Since FFmpeg sends a stream of concatenated images,
# we can't just read until eof.)
function readpngdata(io)
    blk = 65536;
    a = Array{UInt8}(undef, blk)
    readbytes!(io, a, 8)
    if view(a, 1:8) != magic(format"PNG")
        error("Bad magic.")
    end
    n = 8
    while !eof(io)
        if length(a)<n+12
            resize!(a, length(a)+blk)
        end
        readbytes!(io, view(a, n+1:n+12), 12)
        m = 0
        for i=1:4
            m = m<<8 + a[n+i]
        end
        chunktype = view(a, n+5:n+8)
        n=n+12
        if chunktype == codeunits("IEND")
            break
        end
        if length(a)<n+m
            resize!(a, max(length(a)+blk, n+m+12))
        end
        readbytes!(io, view(a, n+1:n+m), m)
        n = n+m
    end
    resize!(a,n)
    return a
end

"Read a frame from a video"
readframe(io::IO) = ImageMagick.load_(readpngdata(io))

"Write a frame to a video"
writeframe(io::IO, img) = show(io, MIME("image/png"), img)
# Bypass re-scaling:
writeframe(io::IO, img::Array{T,2} where T<:Colorant) = save(Stream(format"PNG", io), img)

end # module
