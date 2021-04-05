# TODO: escape stuff
Base.show(io::IO, mime::MIME"text/plain", node::Node) = html(io, node, mime)
Base.show(io::IO, mime::MIME"text/html", node::Node) = html(io, node, mime)

pairtag(pair::Pair) = "$(first(pair))=\"$(last(pair))\""
attrstag(node::Node) = isempty(attrs(node)) ? "" : " " * join([pairtag(pair) for pair in attrs(node)], ' ')

begintag(node::Node) = "<$(tag(node))$(attrstag(node))$(isempty(children(node)) ? " /" : "")>"
begintag(::Node{:comment}) = "<!--"
begintag(::Union{Node{:component},Node{:dummy}}) = ""

endtag(node::Node) = "</$(tag(node))>"
endtag(::Node{:comment}) = "-->"
endtag(::Union{Node{:component},Node{:dummy}}) = ""

# Inspired by <https://github.com/JuliaLang/julia/blob/master/stdlib/Markdown/src/render/rich.jl>
function bestmime(x!)
    for mime in ("text/html", "image/svg+xml", "image/png", "text/plain")
        showable(mime, x!) && return MIME(Symbol(mime))
    end
    error("Cannot render $x! to HTML.")
end

function html(io::IO, node::Node, mime)
    print(io, begintag(node))
    if !isempty(children(node))
        for child in children(node)
            html(io, child, mime)
        end
        print(io, endtag(node))
    end
end
function html(io::IO, node::Node, ::MIME"text/html")
    print(io, begintag(node))
    if !isempty(children(node))
        for child in children(node)
            html(io, child, bestmime(child))
        end
        print(io, endtag(node))
    end
end
html(io::IO, x, mime) = show(io, mime, x)  # Objects as they appear in the REPL
html(io::IO, str::AbstractString, mime) = print(io, str)  # No quotation marks for strings
# html(io::IO, x, ::MIME"text/html") = html(io, x, bestmime(x))  # fallback

# TODO: support and test "image/svg+xml" and "image/png", see ideas here: <https://github.com/JuliaLang/julia/blob/master/stdlib/Markdown/src/render/rich.jl>