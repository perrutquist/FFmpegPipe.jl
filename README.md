# FfmpegPipe.jl - Save videos from Julia

[![Build Status](https://travis-ci.org/perrutquist/FfmpegPipe.jl.svg?branch=master)](https://travis-ci.org/perrutquist/FfmpegPipe.jl)

[![Coverage Status](https://coveralls.io/repos/perrutquist/FfmpegPipe.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/perrutquist/FfmpegPipe.jl?branch=master)

[![codecov.io](http://codecov.io/github/perrutquist/FfmpegPipe.jl/coverage.svg?branch=master)](http://codecov.io/github/perrutquist/FfmpegPipe.jl?branch=master)

FfmpegPipe lets you read/write video files (`mp4`, `wmv`, `avi`, `mov`...) from Julia by piping images from/to an `ffmpeg` process.

This is neither as efficient nor as versatile as calling lower-level routines from libav/ffmpeg directly, like [VideoIO.jl](https://github.com/kmsquire/VideoIO.jl) does, but that package does not yet support video output.

Anything that Julia can `show` as an `image/png` can be sent as a video frame,
in particular `Plot` objects from [Plots.jl](https://github.com/JuliaPlots/Plots.jl)
and `Array{RGB,2}` objects from [Images.jl](https://github.com/JuliaImages/Images.jl)
will work.

(Yes, it is unnecessary to compress/decompress a PNG image only to pass it form
one process to another, but at least the process is lossless.)
