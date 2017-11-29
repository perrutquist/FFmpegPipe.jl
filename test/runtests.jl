using FFmpegPipe
using Base.Test
using Plots

f1 = tempname()*".mp4"

s = openvideo(f1, "w", r=24)
pyplot()
for a in linspace(0, pi, 24)
    x = a+linspace(0, pi, 100)
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

rm(f1)
@test isfile(f2)
rm(f2)
