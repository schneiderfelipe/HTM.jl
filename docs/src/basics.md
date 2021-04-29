```@meta
DocTestSetup = quote
    using HTM
end
```

# Basic usage

HTM.jl provides a [non-standard string literal](https://docs.julialang.org/en/v1/manual/strings/#non-standard-string-literals) macro (`@htm_str`) for
generating HTML with a syntax inspired by
[JSX](https://reactjs.org/docs/introducing-jsx.html),
[lit-html](https://lit-html.polymer-project.org/guide),
[`htm`](https://github.com/developit/htm),
and [Hypertext Literal](https://observablehq.com/@observablehq/htl).
HTM.jl interpolates embedded Julia expressions based on context, allowing automatic processing
and non-serializable values, such as functions, structures, and other HTML nodes.

```@example
using HTM

url(w, h) = "https://placekitten.com/g/$(w)/$(h)"
placekitten(w=450, h=300) = htm"<img src=$(url(w, h)) />"

htm"<p>$(placekitten())</p>"
```

What follows is a step-by-step guide of its main features.

## Features

HTM.jl renders markup as elements, `String`, or `nothing`:

```jldoctest
julia> htm"<em>I'm an element!</em>"
<em>I&#39;m an element&#33;</em>
```

```jldoctest
julia> htm"I'm text."
"I'm text."
```

```jldoctest
julia> htm"" === nothing  # I'm nothing.
true
```

Multiple top-level nodes ("document fragments") are represented as tuples:

```jldoctest
julia> htm"<div /><div />"
(<div></div>, <div></div>)
```

### Objects are nodes, and nodes are objects

Embedded Julia expressions are interpolated appropriately.
Interpolated data values are inserted into the result at the corresponding location as is.
That means that the backend can use Julia's display system to render anything showable as `text/html`:

```@example
using HTM, Plots  # hide

default(size=(250, 250))  # hide
htm"""<div style="display: flex">
    <span style="transform: rotate(-5deg)">
        $(plot(sin, -2π, 2π, label="sin"))
    </span>
    $(plot(cos, -2π, 2π, label="cos"))
</div>"""
```

So if you have a function that generates a node (say itself using HTM.jl), you can embed the result into another HTM.jl.

```@example
using HTM  # hide

emphasize(text) = htm"<em>$(text)</em>"

htm"<p><strong>This is $(emphasize(\"really\")) important.</strong></p>"
```

Escaping is left to the backend, which works perfectly with Hyperscript.jl, the default backend:

```jldoctest
julia> htm"<span>Look, Ma, $(\"<em>automatic escaping</em>\")!</span>"
<span>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</span>
```

```jldoctest
julia> htm"<font color=$(\"red\")>This text has color.</font>"
<font color="red">This text has color.</font>
```

### Iterables will be iterated

You can interpolate iterables into data, too, even iterables of nodes.
They get concatenated by the default backend:

```@example
using HTM  # hide

htm"<p><strong>It's as easy as $([1, 2, 3])</strong></p>"
```

That is useful for mapping data to content via `map` or broadcast:

```@example
using HTM  # hide
using Colors

rows = map(enumerate(colormap("Oranges", 5))) do (i, color)
    htm"""<tr>
        <td>$(i)</td>
        <td><code>#$(hex(color))</code></td>
        <td style="background: #$(hex(color));"></td>
    </tr>"""
end

header = htm"""<tr>
    $(htm"<th>$(h)</th>" for h in ["#", "Color", "Swatch"])
</tr>"""

htm"""<table>
    <thead>$(header)</thead>
    <tbody>$(rows)</tbody>
</table>"""
```

### Optional (and boolean) attributes are optional

If an attribute value is `false`, it's as if the attribute hadn't been specified.
Conversely, if an attribute value is `true`, it's equivalent to the empty string.

```@example
using HTM  # hide

htm"<p><button disabled=$(true)>Can't click me</button></p>"
```

`nothing` and `missing` attributes behave the same as `false`:

```@example
using HTM  # hide

htm"<p><button disabled=$(nothing)>Can click me</button></p>"
```

`nothing` or `missing` nodes are not rendered:

```@example
using HTM  # hide

htm"<p><strong>There's no $(nothing) here.</strong></p>"
```

### Spread your attributes

You can set multiple attributes by interpolating an object in place of attributes:

```@example
using HTM  # hide

props = Dict(
    "onmouseover" => "this.style.transform = 'rotate(5deg)'",
    "onmousedown" => "this.style.transform = 'rotate(25deg)'",
    "onmouseup" => "this.style.transform = 'rotate(5deg)'",
    "onmouseout" => "this.style.transform = ''",
    "onclick" => "alert('You clicked! 🎉')",
)

htm"<p><button $(props)>Click me</button></p>"
```

## Why not concatenate?

Indeed the simplest way to generate web content is to write HTML.
Yet, simple concatenation has two significant drawbacks.

First, it confounds markup with text and other content.
If an interpolated value happens to include characters that are meaningful markup, the result may render unexpectedly.
An ampersand (`&`) can be interpreted as a character entity reference, for instance.

```@example
currencies = "dollars&pounds"

HTML("<p><strong>My favorite currencies are $(currencies).</strong></p>")
```

```@example
using HTM  # hide
currencies = "dollars&pounds"  # hide

htm"<p><strong>My favorite currencies are $(currencies).</strong></p>"
```

Second, you lose composition: interpolated content must be serialized as markup.
You cannot combine literal HTML with content created by libraries such as Plots.jl.
And some content, such as event listeners implemented as closures through JSExpr.jl, can't be serialized.

```@example
using HTM, Plots  # hide

HTML("<p style=\"transform: rotate(5deg)\">$(plot(x -> x^2, -1, 1))</p>")
```
