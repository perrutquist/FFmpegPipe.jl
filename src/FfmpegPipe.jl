module FfmpegPipe

using Images
using FileIO
using ImageMagick # alternatively: QuartsImageIO

const ffmpeg = "ffmpeg" # name of executable

struct ffmpegIO
    io::IO
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
function openvideo(filename::String, ::Val{:r}; loglevel="fatal")
    cmd = `$ffmpeg -loglevel $loglevel -nostats -i $filename -f image2pipe -vcodec png -compression_level 0 -`
    ffmpegIO(open(cmd)[1])
end

"""
`openvideo(file, :w)` opens movie file for writing
"""
function openvideo(filename::String, ::Val{:w}; r=24, q=3, vcodec="h264", loglevel="fatal")
    cmd = `$ffmpeg -loglevel $loglevel -nostats -f image2pipe -vcodec png -r $r -i - -vcodec $vcodec -q $q $filename`
    io = ffmpegIO(open(cmd, "w")[1])
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
read(stream::ffmpegIO) = ImageMagick.load_(readpngdata(stream.io))

"Write a frame to a video"
@generated function write(stream::ffmpegIO, img)
    if method_exists(save, (Stream{format"PNG"}, img))
        :( save(Stream(format"PNG", stream.io), img) )
    else
        :( show(stream.io, MIME("image/png"), img) )
    end
end

end # module
