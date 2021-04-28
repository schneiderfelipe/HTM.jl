# [HyperscriptLiteral.jl](https://github.com/schneiderfelipe/HyperscriptLiteral.jl)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl)

A juicy way of writing HTML in Julia. 🍍

```jldoctest
julia> using HyperscriptLiteral

julia> whom = "🌍!";

julia> htm"<h1>Hello, $(whom)</h1>"
<h1>Hello, 🌍&#33;</h1>
```

HyperscriptLiteral.jl parses HTML into [Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) objects.

This is a work in progress!

Please help us improve by sharing your feedback. 🙏
TODO: link to issues

## Installation

HyperscriptLiteral.jl is open-source, small (<250 SLOCs), has no dependencies
(TODO: currently not true), and can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```julia
pkg> add HyperscriptLiteral  # TODO: register package
```

## Roadmap

- [ ] Full support of [HTML5](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).
- [ ] Full (Julian) support of [observablehq/htl](https://github.com/observablehq/htl)
- [ ] Full (Julian) support of [developit/htm](https://github.com/developit/htm) (when it can be compatible with Hyperscript.jl).
- [ ] Hyperscript.jl as sole dependency.
  - [ ] Support all features of Hyperscript.jl.
- [ ] `@htm_str` macro.
  - [ ] Too similar to `@html_str`, change to something else.
