using FfmpegPipe
using Base.Test
using Plots

s = openvideo("sinecurve.mp4", "w", r=24)
pyplot()
for a in linspace(0, pi, 3*24)
    x = a+linspace(0, pi, 1000)
    plt = plot(x, sin.(x))
    writeframe(s, plt)
end
close(s)

@test isfile(s1)

s1 = openvideo("sinecurve.mp4", "r")
s2 = openvideo("upsidecurve.mp4", "w", r=24)
while !eof(s1)
    img = readframe(s1)
    writeframe(s2, img[end:-1:1,:])
end
close(s2)
close(s1)

@test isfile(s2)
