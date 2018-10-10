using FFmpegPipe
using Test
using Plots
gr()

f1 = tempname()*".mp4"

s = openvideo(f1, "w", r=24)
for a in range(0, stop=pi, length=24)
    x = a .+ range(0, stop=pi, length=100)
    plt = plot(x, sin.(x))
    writeframe(s, plt)
end
close(s)

@test isfile(f1)

f2 = tempname()*".mp4"

s1 = openvideo(f1, "r")
s2 = openvideo(f2, "w", r=24)
while !eof(s1)
    img = readframe(s1)
    writeframe(s2, img[end:-1:1,:])
end
close(s2)
close(s1)

@test isfile(f2)

rm(f2)

w = 103
h = 97
s1 = openvideo(f1, "r", ss_in = 0.5, s_out = "$(w)x$h")
img = readframe(s1)
@test size(img) == (h, w)
close(s1)

rm(f1)

