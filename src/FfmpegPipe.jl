module FfmpegPipe

using Images
using FileIO
using ImageMagick # alternatively: QuartsImageIO

const ffmpeg = "ffmpeg" # name of executable

struct ffmpegIO{T}
    io::Stream{T}
end
Base.close(p::ffmpegIO) = close(p.io)
Base.eof(p::ffmpegIO) = eof(p.io)

"""
Open a movie file using ffmpeg's image2pipe interface.
"""
openvideo(filename::String) = openvideo(filename, Val{:r}())
openvideo(filename::String, mode::Symbol) = openvideo(filename, Val{mode}())
openvideo(filename::String, mode::Union{Char,String}) = openvideo(filename, Symbol(mode))

"""
`openvideo(file, :r)` opens movie file for reading
"""
function openvideo(filename::String, ::Val{:r})
    cmd = `$ffmpeg -i $filename -f image2pipe -vcodec png -`
    ffmpegIO(Stream(format"PNG", open(cmd)[1]))
end

"""
`openvideo(file, :w)` opens movie file for writing
"""
function  openvideo(filename::String, ::Val{:w})
    cmd = `$ffmpeg -f image2pipe -vcodec png -i - -vcodec h264 $filename`
    ffmpegIO(Stream(format"PNG", open(cmd, "w")[1]))
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
# (Since ffmpeg sends a stream of concatenated images,
# we can't just read until eof.)
function read(io::Stream{format"PNG"})
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
        readbytes!(io, view(a, n+1:n+m+12), m)
        n = n+m
    end
    resize!(a,n)
    return a
end

"Read a frame from a video"
function read(stream::ffmpegIO)
    ImageMagick.load_(read(stream.io))
end

"Write a frame to a video"
function write(stream::ffmpegIO, img)
    write(stream.io, img)
end

end # module
