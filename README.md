# JSX.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schneiderfelipe.github.io/JSX.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schneiderfelipe.github.io/JSX.jl/dev)
[![Build Status](https://github.com/schneiderfelipe/JSX.jl/workflows/CI/badge.svg)](https://github.com/schneiderfelipe/JSX.jl/actions)
[![Coverage](https://codecov.io/gh/schneiderfelipe/JSX.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schneiderfelipe/JSX.jl)

A different way of writing HTML in Julia, using JSX ideas.

```julia
using JSX

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