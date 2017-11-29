module FFmpegPipe

using Images
using FileIO
using ImageMagick # alternatively: QuartsImageIO

export openvideo, readframe, writeframe

const ffmpeg = "ffmpeg" # name of executable

"""
Open a movie file using ffmpeg's image2pipe interface.
"""
openvideo(filename::String; kwargs...) = openvideo(filename, Val{:r}(); kwargs...)
openvideo(filename::String, mode::Symbol; kwargs...) = openvideo(filename, Val{mode}(); kwargs...)
openvideo(filename::String, mode::Union{Char,String}; kwargs...) = openvideo(filename, Symbol(mode); kwargs...)

"""
`openvideo(file, :r)` opens movie file for reading
"""
function openvideo(filename::String, ::Val{:r}; loglevel="fatal")
    cmd = `$ffmpeg -loglevel $loglevel -nostats -i $filename -f image2pipe -vcodec png -compression_level 0 -`
    open(cmd)[1]
end

"""
`openvideo(file, :w)` opens movie file for writing
"""
function openvideo(filename::String, ::Val{:w}; r=24, q=3, vcodec="h264", loglevel="fatal")
    cmd = `$ffmpeg -loglevel $loglevel -nostats -f image2pipe -vcodec png -r $r -i - -vcodec $vcodec -q $q $filename`
    open(cmd, "w")[1]
end

function openvideo(f::Function, filename::String, mode)
    io = openvideo(filename, mode)
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
    const blk = 65536;
    a = Array{UInt8}(blk)
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
        if chunktype == Array{UInt8}("IEND")
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
