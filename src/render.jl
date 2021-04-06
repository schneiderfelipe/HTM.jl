Base.show(io::IO, mime::MIME"text/plain", node::Node) = html(io, node, mime)
Base.show(io::IO, mime::MIME"text/html", node::Node) = html(io, node, mime)

pairtag(pair::Pair) = "$(escape(first(pair), TagContext()))=\"$(escape(last(pair), AttributeContext()))\""
attrstag(node::Node) = isempty(attrs(node)) ? "" : " " * join(map(pairtag, attrs(node)), ' ')

begintag(node::Node) = "<$(escape(tag(node), TagContext()))$(attrstag(node))$(isempty(children(node)) ? " /" : "")>"
begintag(::Node{:comment}) = "<!--"
begintag(::Node{:dummy}) = ""

endtag(node::Node) = "</$(escape(tag(node), TagContext()))>"
endtag(::Node{:comment}) = "-->"
endtag(::Node{:dummy}) = ""

# Unescaped
uendtag(node::Node) = "</$(tag(node))>"
uendtag(node::Node{:comment}) = endtag(node)
uendtag(node::Node{:dummy}) = endtag(node)

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
html(io::IO, str::AbstractString, mime) = print(io, escape(str, NodeContext()))  # No quotation marks for strings
# html(io::IO, x, ::MIME"text/html") = html(io, x, bestmime(x))  # fallback

# TODO: support and test "image/svg+xml" and "image/png", see ideas here: <https://github.com/JuliaLang/julia/blob/master/stdlib/Markdown/src/render/rich.jl>

# Inspired by <https://github.com/yurivish/Hyperscript.jl/blob/master/src/Hyperscript.jl#L171>
escape(str::AbstractString, context::AnyContext) = *(map(c -> get(escapes(context), c, c), collect(str))...)  # ugly!
escape(x, context::AnyContext) = escape(sprint(print, x), context)

chardict(chars) = Dict(c => "&#$(Int(c));" for c in chars)
escapes(::Union{TagContext,NodeContext}) = chardict("&<>\"'`!@\$%()=+{}[]")
escapes(::AttributeContext) = chardict("&<>\"\n\r\t")