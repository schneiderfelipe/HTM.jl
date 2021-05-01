```@meta
DocTestSetup = quote
    using HTM

    🍍() = htm"<img src=$(pineapple) />"
end
```

# Usage guide

HTM.jl provides a
[non-standard string literal](https://docs.julialang.org/en/v1/manual/strings/#non-standard-string-literals)
macro (`@htm_str`) for generating HTML with a syntax inspired by
[`htm`](https://github.com/developit/htm),
[JSX](https://reactjs.org/docs/introducing-jsx.html),
[and](https://lit-html.polymer-project.org/guide)
[others](https://observablehq.com/@observablehq/htl).
HTM.jl interpolates
[embedded Julia expressions](https://docs.julialang.org/en/v1/manual/strings/#string-interpolation)
based on context:

```@example
using HTM

# Photograph by Suniltg at Wikimedia Commons, distributed under a CC-BY 3.0 license.
pineapple = "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg/800px-%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg"  # hide
🍍() = htm"<img src=$(pineapple) />"
htm"<p><a href=$(pineapple)>$(🍍())</a></p>"
```

What follows is a step-by-step guide of its main features.

## Basic features

HTM.jl parses markup as nodes, `String` (or objects in general), or `nothing`:

```jldoctest
julia> htm"<div>🍍</div>"
<div>🍍</div>
```

```jldoctest
julia> htm"🍍"
"🍍"
```

```jldoctest
julia> htm"" === nothing
true
```

Multiple top-level elements
(["document fragments"](https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment))
are represented as tuples:

```jldoctest
julia> htm"<div /><div />"
(<div></div>, <div></div>)
```

### Objects as elements

Embedded Julia expressions are interpolated appropriately, allowing automatic
processing and non-serializable objects.
The backend ([Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl) by
default) will usually use
[Julia's display system](https://youtu.be/S1Fb5oNhhbc) to render anything
showable as HTML:

```@example
using HTM  # hide
using Plots

default(size=(250, 250))  # hide
# Graph simplified from <https://www.desmos.com/calculator/eds5nef5cj>.
p = begin
    plot!(θ -> 30.4 / (2 + sin(θ)) - 9.5, 0, 2π, color=:brown, proj=:polar, legend=nothing)
    for (a, b) in zip([-4  , 3  ,  9.6, 16.2, 22.7, 29.2, 35.7],
                      [ 0.4, 6.3, 12.3, 18.3, 24.4, 30.5, 36.5])
        plot!(θ -> θ / 2 + 2sin(4π * θ), a, b, color=:orange)
    end
    plot!(θ -> 7(1 - sin(11θ)), 0.12, 3, color=:green)
end

pineapple = "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg/800px-%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg"  # hide
🍍() = htm"<img src=$(pineapple) />"  # hide
htm"""<div style="display: flex">
    <div style="transform: rotate(5deg)">$(p)</div>
    <div style="max-width: 50%">$(🍍())</div>
</div>"""
```

So if you have a function that generates an element (say by using
HTM.jl), you can embed the result into another element:

```@example
using HTM  # hide

orange(text) = htm"<span style=\"background: orange\">$(text)</span>"
htm"<p><strong>This is $(orange(\"really\")) important.</strong></p>"
```

HTM.jl allows you to interpolate tags as well:

```jldoctest
julia> htm"<h$(4)>I'm a header<//>"
<h4>I&#39;m a header</h4>
```

!!! info
    The universal end-tag `<//>` above is a convenience taken from
    [`htm`](https://github.com/developit/htm).

[Escaping](https://stackoverflow.com/q/7381974/4039050) is left to the
backend, which works really nice by default:

```jldoctest
julia> htm"<p>Look, Ma, $(\"<em>automatic escaping</em>\")!</p>"
<p>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</p>
```

Note that `nothing` elements are not rendered by the default backend:

```@example
using HTM  # hide

htm"<p><strong>There's no $(nothing) here.</strong></p>"
```

### Iterable objects

You can interpolate iterables into data, too, even iterables of elements:

```@example
using HTM  # hide

htm"<p><strong>Easy as $([1, 2, 3])</strong></p>"
```

That is useful for mapping data to content via
[`map`](https://docs.julialang.org/en/v1/base/collections/#Base.map) or by
[broadcasting](https://docs.julialang.org/en/v1/manual/arrays/#Broadcasting):

```@example
using HTM  # hide
using Colors

# Example taken from <https://observablehq.com/@observablehq/htl>.
rows = map(enumerate(colormap("Oranges", 5))) do (i, color)
    htm"""<tr>
        <td>$(i)</td>
        <td><code>#$(hex(color))</code></td>
        <td style="background: #$(hex(color));"></td>
    </tr>"""
end

header = htm"""<tr>
    $(htm"<th>$(column)</th>" for column in ["#", "Color", "Swatch"])
</tr>"""

htm"""<table>
    <caption>Five shades of 🍍</caption>
    <thead>$(header)</thead>
    <tbody>$(rows)</tbody>
</table>"""
```

### Optional attributes

If an attribute value is `false`, it's as if the attribute hadn't been
specified.
Conversely, if an attribute value is `true`, it's equivalent to the empty
string.
This is useful for setting an attribute based on a boolean flag:

```@example
using HTM  # hide

htm"<p><button disabled=$(true)>Can't click me</button></p>"
```

`nothing` attributes behave the same as `false`:

```@example
using HTM  # hide

htm"<p><button disabled=$(nothing)>Can click me</button></p>"
```

### Spread attributes

You can set multiple attributes by interpolating a dictionary in place of
attributes:

```@example
using HTM  # hide

attrs = Dict(
    "onmouseover" => "this.style.transform = 'rotate(5deg)'",
    "onmousedown" => "this.style.transform = 'rotate(25deg)'",
    "onmouseup" => "this.style.transform = 'rotate(5deg)'",
    "onmouseout" => "this.style.transform = ''",
    "onclick" => "alert('You clicked! 🍍🎉')",
)

htm"<p><button $(attrs)>Click me</button></p>"
```

## Why not concatenate?

Indeed the simplest way to generate web content is to write HTML.
Yet, simple concatenation has two significant drawbacks:

**It confounds markup with text and other content**:
if an interpolated value happens to include characters that are meaningful
markup, the result may render unexpectedly.
An ampersand (`&`) can be interpreted as a character entity reference, for
instance:

```@example
currencies = "dollars&pounds"

HTML("<p><strong>My favorite currencies are $(currencies).</strong></p>")
```

Compare the above with the following:

```@example
using HTM  # hide
currencies = "dollars&pounds"  # hide

htm"<p><strong>My favorite currencies are $(currencies).</strong></p>"
```

**You lose composition**:
interpolated content must be serialized as markup.
You cannot combine literal HTML with content created by libraries such as
[Plots.jl](http://docs.juliaplots.org/latest/).
And some content can't be serialized:

```@example
using HTM, Plots  # hide

HTML("<p style=\"display:   inline-block; transform: rotate(180deg)\">
    🍍
    $(plot(x -> x^2, -1, 1))
</p>")
```

The above is probably *not* what you want.
