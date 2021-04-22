# HyperscriptLiteral.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/HyperscriptLiteral.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/HyperscriptLiteral.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/HyperscriptLiteral.jl)

🍊 A different way of writing HTML in Julia, using HyperscriptLiteral ideas.

```julia
using HyperscriptLiteral

sayhi(whom) = htm"<title>Hello, $(whom)</title>"

sayhi("world!")
# => <title>Hello, world&#33;</title>
```

Components are also supported:

```julia
function usergreeting()
    return htm"<h1>Welcome back!</h1>"
end

function guestgreeting()
    return htm"<h1>Please sign up.</h1>"
end

function greeting(; isloggedin=false)
    if isloggedin
        return htm"<usergreeting />"
    end
    return htm"<guestgreeting />"
end

htm"<greeting isloggedin=true />"
# => <h1>Welcome back&#33;</h1>
```
