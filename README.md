# HyperscriptLiteral.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl)

A juicy way of writing HTML in Julia. 🍍

```julia
using HyperscriptLiteral

sayhi(whom) = htm"<title>Hello, $(whom)</title>"

sayhi("world!")
# => <title>Hello, world&#33;</title>
```

HyperscriptLiteral.jl parses HTML into [Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) objects.

## Related packages

See [HypertextLiteral.jl](https://github.com/MechanicalRabbit/HypertextLiteral.jl) for a related package.

## Roadmap

- [ ] Full support of [HTML5](https://html.spec.whatwg.org/multipage/parsing.html#tokenization).
- [ ] Full (Julian) support of [observablehq/htl](https://github.com/observablehq/htl)
- [ ] Full (Julian) support of [developit/htm](https://github.com/developit/htm) (when it can be compatible with Hyperscript.jl).
- [ ] Hyperscript.jl as sole dependency.
  - [ ] Support all features of Hyperscript.jl.
  - [ ] Compare with Hyperscript.jl in the documentation.
- [ ] `@htm_str` macro.