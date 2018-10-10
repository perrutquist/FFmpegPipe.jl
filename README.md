# FFmpegPipe.jl - Save videos from Julia

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/yakir12/FFmpegPipe.jl.svg?branch=master)](https://travis-ci.org/yakir12/FFmpegPipe.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/70gsn9q8f2w7ko68?svg=true)](https://ci.appveyor.com/project/yakir12/ffmpegpipe-jl)
[![codecov.io](http://codecov.io/github/yakir12/FFmpegPipe.jl/coverage.svg?branch=master)](http://codecov.io/github/yakir12/FFmpegPipe.jl?branch=master)

FFmpegPipe lets you read/write video files (mp4, wmv, avi, mov...) from Julia by piping images from/to an [FFmpeg](https://ffmpeg.org/) process.

This is neither as efficient nor as versatile as calling lower-level routines from libav/ffmpeg directly, like [VideoIO.jl](https://github.com/kmsquire/VideoIO.jl) does, but that package does not yet support video output.

Anything that Julia can `show` as a `MIME("image/png")` can be sent as a video frame,
in particular `Plot` objects from [Plots.jl](https://github.com/JuliaPlots/Plots.jl)
and `Array{T,2} where T<:Colorant` from [Images.jl](https://github.com/JuliaImages/Images.jl)
have been tested to work.
(Yes, it is unnecessary to compress/decompress a PNG image only to pass it form
one process to another, but at least it is lossless.)

## Examples

We can create a movie by generating lots of plots and writing each one to
the movie as a frame.

Plots.jl and FFmpeg must already be installed, or this will not work.

```julia
using FFmpegPipe
using Plots
s = openvideo("sinecurve.mp4", "w", r=24)
pyplot()
for a in linspace(0, pi, 3*24)
    x = a+linspace(0, pi, 1000)
    plt = plot(x, sin.(x))
    writeframe(s, plt)
end
close(s)
```

We can apply an effect by reading frames from one move and writing modified
frames to another movie. However, all information except the images themselves
(sound, subtitles, framerate, metadata...)
will need to be transfered to the new movie in some other way.

```julia
s1 = openvideo("sinecurve.mp4", "r")
s2 = openvideo("upsidecurve.mp4", "w", r=24)
while !eof(s1)
    img = readframe(s1)
    writeframe(s2, img[end:-1:1,:])
end
close(s2)
close(s1)
```

# Note

This is just a simple wrapper.
The author of this package is not affiliated with the authors of FFmpeg in any way.

FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
