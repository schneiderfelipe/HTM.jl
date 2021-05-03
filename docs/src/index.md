```@eval
using Markdown

let md = read("../../README.md", String)
    md = replace(md, "```julia" => "```julia-repl")
    Markdown.parse(md)
end
```
