using FFmpegPipe
using Test
using Plots

f1 = tempname()*".mp4"

s = openvideo(f1, "w", r=24)
pyplot()
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

s1 = openvideo(f1, "r", options = (s = "100x101",))
img = readframe(s1)

@test size(img) == (101, 100)

rm(f1)
