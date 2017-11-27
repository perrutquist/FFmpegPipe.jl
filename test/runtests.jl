using FfmpegPipe
using Base.Test

const testfilm = joinpath(ENV["HOME"], "Downloads", "ladybird.mp4")

if isfile(testfilm)
    println("Test film missing. Fix this by running:")
    println("curl https://archive.org/download/LadybirdOpeningWingsCCBYNatureClip/Ladybird%20opening%20wings%20CC-BY%20NatureClip.mp4 -o $testfilm")
end

@test isfile(testfilm)
