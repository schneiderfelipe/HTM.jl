```@meta
DocTestSetup = quote
    using HTM
    using HypertextLiteral
end
```

# Comparison to [HypertextLiteral.jl](https://github.com/MechanicalRabbit/HypertextLiteral.jl)

HypertextLiteral.jl is an excellent Julia package that provides essentially
the same functionality as HTM.jl.
Because of the quality of HypertextLiteral.jl, there's no reason keep
maintaining HTM.jl as well, and thus I've decided to retire HTM.jl.
As such, this page lists some compared usage examples between the two
packages.

## Basic features

Basic tags:

```jldoctest
julia> htm"<div>🍍</div>"
<div>🍍</div>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<div>🍍</div>"
<div>🍍</div>
```

Single strings:

```jldoctest
julia> htm"🍍"
"🍍"
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"🍍"
🍍
```

Empty strings:

```jldoctest
julia> htm""

julia> typeof(htm"")
Nothing
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl""


julia> typeof(htl"")
HypertextLiteral.Result
```

Multiple top-level elements:

```jldoctest
julia> htm"<div /><div />"
2-element Vector{Hyperscript.Node{Hyperscript.HTMLSVG}}:
 <div></div>
 <div></div>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<div /><div />"
<div /><div />
```

So it's basically the same thing.

## Objects as elements

Simple functions:

```jldoctest
julia> orange(text) = htm"<span style=\"background: orange\">$(text)</span>"
orange (generic function with 1 method)

julia> htm"<p><strong>This is $(orange(\"really\")) important.</strong></p>"
<p><strong>This is <span style="background: orange">really</span> important.</strong></p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> orange(text) = htl"<span style=\"background: orange\">$(text)</span>"
orange (generic function with 1 method)

julia> htl"<p><strong>This is $(orange(\"really\")) important.</strong></p>"
<p><strong>This is <span style="background: orange">really</span> important.</strong></p>
```

Markdown objects:

```jldoctest
julia> using Markdown

julia> htm"<div>$(md\"# 🍍\")</div>"
<div><div class="markdown"><h1>🍍</h1>
</div></div>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> using Markdown  # hide

julia> htl"<div>$(md\"# 🍍\")</div>"
<div><div class="markdown"><h1>🍍</h1>
</div></div>
```

Raw HTML objects:

```jldoctest
julia> htm"<p>🍍$(html\"&nbsp;\")🍌</p>"
<p>🍍&nbsp;🍌</p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<p>🍍$(html\"&nbsp;\")🍌</p>"
<p>🍍&nbsp;🍌</p>
```

Unfortunately, it's not possible to interpolate tag names in
HypertextLiteral.jl (nor use `<//>`):

```jldoctest
julia> htm"<h$(4)>I'm a header<//>"
<h4>I&#39;m a header</h4>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```julia
julia> htl"<h$(4)>I'm a header<h$(4)>"
ERROR: LoadError: "unexpected binding STATE_TAG_NAME"
Stacktrace:
 [1] interpolate(args::Vector{Any})
   @ HypertextLiteral ~/.julia/packages/HypertextLiteral/5lm4Q/src/lexer.jl:105
 [2] var"@htl_str"(__source__::LineNumberNode, __module__::Module, expr::String)
   @ HypertextLiteral ~/.julia/packages/HypertextLiteral/5lm4Q/src/macro.jl:95
in expression starting at REPL[23]:1

julia> htl"<h4>I'm a header<//>"
ERROR: LoadError: DomainError with //>:
invalid first character of tag name
Stacktrace:
 [1] interpolate(args::Vector{Any})
   @ HypertextLiteral ~/.julia/packages/HypertextLiteral/5lm4Q/src/lexer.jl:152
 [2] var"@htl_str"(__source__::LineNumberNode, __module__::Module, expr::String)
   @ HypertextLiteral ~/.julia/packages/HypertextLiteral/5lm4Q/src/macro.jl:95
in expression starting at REPL[24]:1
```

Escaping characters:

```jldoctest
julia> htm"<p>Look, Ma, $(\"<em>automatic escaping</em>\")!</p>"
<p>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<p>Look, Ma, $(\"<em>automatic escaping</em>\")!</p>"
<p>Look, Ma, &lt;em>automatic escaping&lt;/em>!</p>
```

`Nothing` objects:

```jldoctest
julia> htm"<p><strong>There's no $(nothing) here.</strong></p>"
<p><strong>There&#39;s no  here.</strong></p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<p><strong>There's no $(nothing) here.</strong></p>"
<p><strong>There's no  here.</strong></p>
```

## Iterable objects

```jldoctest
julia> htm"<p><strong>Easy as $([1, 2, 3])</strong></p>"
<p><strong>Easy as 123</strong></p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<p><strong>Easy as $([1, 2, 3])</strong></p>"
<p><strong>Easy as 123</strong></p>
```

## Optional attributes

```jldoctest
julia> htm"<p><button disabled=$(true)>Can't click me</button></p>"
<p><button disabled>Can&#39;t click me</button></p>
```

☝️ HTM.jl / HypertextLiteral.jl 👇

```jldoctest
julia> htl"<p><button disabled=$(true)>Can't click me</button></p>"
<p><button disabled=''>Can't click me</button></p>
```

HypertextLiteral.jl has a lot of extra features, take a look at the
[documentation](https://mechanicalrabbit.github.io/HypertextLiteral.jl/stable/).
