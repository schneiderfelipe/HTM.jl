# 🍍 [HTM.jl](https://github.com/schneiderfelipe/HTM.jl) (Hyperscript Tagged Markup in Julia)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schneiderfelipe.github.io/HTM.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/HTM.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/HTM.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/HTM.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/HTM.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/HTM.jl)

```julia-repl
julia> struct Link{H,C}
           href::H
           children::C
       end

julia> Base.show(io::IO, mime::MIME"text/html", a::Link) =
           show(io, mime, htm"<a href=$(a.href)>$(a.children)</a>")

julia> htm"""<em>$(Link("http://bit.ly/htm-jl", "🥝 HTM.jl"))</em>"""
<em><a href="http://bit.ly/htm-jl">🥝 HTM.jl</a></em>
```

HTM.jl is a small templating library for Julia with a **JSX-like syntax**.

It lets you express HTML as a function of data.
You write HTML templates using a
[non-standard string literal](https://docs.julialang.org/en/v1/manual/strings/#non-standard-string-literals)
with embedded Julia expressions.
This means that **parsing happens at compile time**:

```julia-repl
julia> @macroexpand htm"""<em>$(Link("http://bit.ly/htm-jl", "🥝 HTM.jl"))</em>"""
:(create_element("em", (), (Link("http://bit.ly/htm-jl", "🥝 HTM.jl"),)))
```

## Syntax

The syntax you write when using HTM.jl was inspired by
[JSX](https://reactjs.org/docs/introducing-jsx.html),
[lit-html](https://lit-html.polymer-project.org/guide),
[`htm`](https://github.com/developit/htm),
and [Hypertext Literal](https://observablehq.com/@observablehq/htl).

It is in fact very close to JSX:

- Spread props: `htm"<div $(props)></div>"`
- Self-closing tags: `htm"<div />"`
- Components through [Julia's Display System](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O): `htm"$(Foo())"`
- Boolean attributes: `htm"<div draggable />"`

We also adopted improvements from JavaScript's `htm`:

- HTML's optional quotes: `htm"<div class=foo></div>"`
- Multiple root elements (fragments): `htm"<div /><div />"`

The following was inpired by Hypertext Literal:

- Boolean assignments: `htm"<button disabled=$(true)>Can't click</button>"`
- Optional values: `htm"<button disabled=$(nothing)>Can click</button>"`
- Iterable values: `htm"<div>$([1, 2, 3])</div>"`

## Installation

HTM.jl can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```julia
pkg> add https://github.com/schneiderfelipe/HTM.jl
```

## Usage

Just import the package and you're good to go:

```julia-repl
julia> using HTM

julia> htm"""<a href="/">Hello!</a>"""
<a href="/">Hello&#33;</a>
```

## Advanced usage

Just like `htm`, HTM.jl is a generic library.
This means we can tell it to "compile" to anything by redefining
the `create_element(type, props, children...)` function (which produces
[Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) objects by
default).
The function can actually return anything--HTM.jl never looks at the return
value.

Here's an example of `create_element()` that returns a tuple:

```julia-repl
julia> HTM.create_element(type, props, children...) = (type, props, children)
```

Now we have a `@htm_str` macro that can be used to produce objects in the
format above:

```julia-repl
julia> htm"<h1 id=hello>Hello world!</h1>"
("h1", Dict{String, Any}("id" => "hello"), (("Hello world!",),))
```

If the input has multiple elements at the root level, the output is a
tuple of `create_element` results:

```julia-repl
julia> htm"""
           <h1 id=hello>Hello</h1>
           <div class=world>World!</div>
       """
(("h1", Dict{String, Any}("id" => "hello"), (("Hello",),)), ("div", Dict{String, Any}("class" => "world"), (("World!",),)))
```

## Project status

HTM.jl is a small (<300 lines of code), open-source Julia project.
Its main goal is to create a fully-featured alternative to the
`@html_str` macro.
We also want `@md_str`-like string interpolations, JSX-like syntax, and full
compatibility with Julia objects through Julia's Display System.

The design is backend-agnostic, so it should work with any library that
produces HTML elements.

HTM.jl is a work in progress at the moment, but is already quite useful and
fast.
It may not be ready for production use yet though.
Please help us improve by [sharing your feedback](https://github.com/schneiderfelipe/HTM.jl/issues). 🙏
