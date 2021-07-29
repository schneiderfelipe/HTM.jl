**WARNING**: this project has been retired.
For an excellent alternative, see
[MechanicalRabbit/HypertextLiteral.jl](https://github.com/MechanicalRabbit/HypertextLiteral.jl).

# 🍍 [HTM.jl](https://github.com/schneiderfelipe/HTM.jl) (Hyperscript Tagged Markup in Julia)

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/HTM.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/HTM.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/HTM.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/HTM.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/HTM.jl)

```julia
julia> using HTM

julia> box(content) = htm"<div id=$(rand(1:100))>$(content)</div>"
box (generic function with 1 method)

julia> b = box("Hello HTM.jl🍍!")
<div id="23">Hello HTM.jl🍍&#33;</div>
```

HTM.jl is [**JSX-like syntax**](https://reactjs.org/docs/introducing-jsx.html)
for [Julia](https://julialang.org/).
It is backend-agnostic but uses
[Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) for generating
HTML elements by default:

```julia
julia> dump(b, maxdepth=1)
Hyperscript.Node{Hyperscript.HTMLSVG}
  context: Hyperscript.HTMLSVG
  tag: String "div"
  children: Array{Any}((1,))
  attrs: Dict{String, Any}
```

(One of the advantages of using Hyperscript.jl is that objects are lazily rendered.)

And since `@htm_str` is a macro, **parsing happens at compile time**:

```julia
julia> @macroexpand htm"<div id=$(rand(1:100))>$(content)</div>"
:(create_element("div", process(Dict(("id" => rand(1:100),))), (content,)))
```

## Syntax

The syntax was inspired by
[JSX](https://reactjs.org/docs/introducing-jsx.html),
[lit-html](https://lit-html.polymer-project.org/guide),
[`htm`](https://github.com/developit/htm),
and [Hypertext Literal](https://github.com/observablehq/htl):

- Spread attributes: `htm"<div $(attrs)></div>"`
- Self-closing tags: `htm"<div />"`
- Multiple root elements (fragments): `htm"<div /><div />"`
- Short circuit rendering: `htm"<div>$(hidefruit || '🍍')</div>"`
- Boolean attributes: `htm"<div draggable />"` or `htm"<div draggable=$(true) />"`
- HTML optional quotes: `htm"<div class=fruit></div>"`
- Styles: `htm"<div style=$(style)></div>"`
- Universal end-tags: `htm"<div>🍍<//>"`
- HTML-style comments: `htm"<div><!-- 🍌 --></div>"`

Furthermore, the components can be constructed using
[Julia's display system](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O):
`htm"$(Fruit(\"pineapple\", '🍍'))"`.

## Installation

HTM.jl can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```julia
pkg> add https://github.com/schneiderfelipe/HTM.jl
```

## Usage

[See the documentation](https://schneiderfelipe.xyz/HTM.jl/dev/usage/) (I hope
you like pineapples).

## Project status

HTM.jl is a small (<400 lines of code) open-source Julia project.
It was once called JSX.jl.
Its main goal is to create a fully-featured, backend-agnostic (any library
that produces HTML elements can be used as a backend) alternative to the
`@html_str` macro.
I also wanted `@md_str`-like string interpolations, JSX-like syntax, and full
compatibility with Julia objects through Julia's display system.

HTM.jl is a **work in progress** but is already quite usable and fast.
It may not be ready for production use yet though.
Please help me improve it by
[sharing your feedback](https://github.com/schneiderfelipe/HTM.jl/issues). 🙏
