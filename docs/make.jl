using Documenter, FFmpegPipe

makedocs(
    modules = [FFmpegPipe],
    format = :html,
    sitename = "FFmpegPipe.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/yakir12/FFmpegPipe.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
