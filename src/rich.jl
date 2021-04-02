# Inspired by <https://github.com/JuliaLang/julia/blob/master/stdlib/Markdown/src/render/rich.jl>
function bestmime(val)
    for mime in ("text/html", "image/svg+xml", "image/png", "text/plain")
        showable(mime, val) && return MIME(Symbol(mime))
    end
    error("Cannot render $val to HTML.")
end

html(io::IO, x) = html(io, x, bestmime(x))  # fallback
html(io::IO, str::AbstractString, mime=MIME("text/html")) = print(io, str)  # No quotation marks for strings
html(io::IO, x, mime) = show(io, mime, x)