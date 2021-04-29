```@meta
DocTestSetup = quote
    using HTM

    struct Link{H,C}
        href::H
        children::C
    end
    Base.show(io::IO, mime::MIME"text/html", a::Link) = show(io, mime, htm"<a href=$(a.href)>$(a.children)</a>")
end
```

# Package guide

HTM.jl provides a single Julia macro, `@htm_str` for generating HTML with a syntax inspired by lit-html and HTM.
HTM.jl is a tagged template literal for HTML that interpolates values based on context, allowing automatic escaping and the interpolation of non-serializable values, such as event listeners, style objects, and other HTML nodes and showable objects.

```jldoctest
julia> using HTM

julia> whom = "🌍!";

julia> htm"<h1>Hello, $(whom)</h1>"
<h1>Hello, 🌍&#33;</h1>
```

What follows is a step-by-step guide of all its functionalities.
This guide closely follows the guide for [observablehq/htl](https://github.com/observablehq/htl) [^1].

[^1]: [A guide for observablehq/htl](https://observablehq.com/@observablehq/htl)

## Why not concatenate?

Surely the simplest way to generate web content is to write HTML.
Julia makes it easier to interpolate values into literal HTML thanks to the
`HTML` type:

```jldoctest
julia> whom = "🌍";

julia> HTML("<h1>Hello $(whom)</h1>")
HTML{String}("<h1>Hello 🌍</h1>")
```

(You can't use the `html"..."` syntax here because the `@html_str` macro
doesn't support interpolation.)
Yet simple concatenation has two significant drawbacks.

First, it confounds markup with text and other content.
If an interpolated value happens to include characters that are meaningful markup, the result may render unexpectedly.
An ampersand (&) can be interpreted as a character entity reference, for instance.

```@example
value2 = "dollars&pounds";
HTML("My favorite currencies are $(value2).")
```

This can be fixed by escaping (say replacing ampersands with the corresponding entity, &amp;).
But you must remember to escape every time you interpolate, which is tedious!
And it's easy to forget when many values work as intended without it.

```@example
safe_value2 = replace("dollars&pounds", r"&" => "&amp;")
HTML("My favorite currencies are $(safe_value2).")
```

Second, concatenation impedes composition: interpolated content must be serialized as markup.
You cannot combine literal HTML with content created by libraries such as Plots.jl.
And some content, such as event listeners implemented as closures through JSExpr.jl, can't be serialized!

## Features (HTML)

HTM.jl is a tagged template literal that renders the specified markup as an element, text node, or nothing as appropriate.

```jldoctest
julia> htm"<em>I'm an element!</em>"
<em>I&#39;m an element&#33;</em>
```

```jldoctest
julia> htm"I'm simply text."
"I'm simply text."
```

```jldoctest
julia> htm"" === nothing
true
```

If multiple top-level nodes are given, the nodes are returned as a "document fragment" (a tuple).

```jldoctest
julia> htm"I'm a <em>document fragment</em> (actually a tuple)."
("I'm a ", <em>document fragment</em>, " (actually a tuple).")
```

### Automatic escaping and interpolation

If a value is interpolated into an attribute value or data, it is escaped appropriately so as to not change the structure of the surrounding markup.
This works thanks to Hyperscript.jl.

```jldoctest
julia> htm"<span>Look, Ma, $(\"<em>automatic escaping</em>\")!</span>"
<span>Look, Ma, &#60;em&#62;automatic escaping&#60;/em&#62;&#33;</span>
```

```jldoctest
julia> htm"<font color=$(\"red\")>This text has color.</font>"
<font color="red">This text has color.</font>
```

In cases where it is not possible to interpolate safely, namely with script and style elements where the interpolated value contains the corresponding end tag, an error is thrown.

```jldoctest
julia> htm"<script>$(\"</script>\")</script>"  # BUG: not what should happen
<script>&#60;/script&#62;</script>
```

### Boolean attributes

If an attribute value is false, it's as if the attribute hadn't been specified.
If an attribute value is true, it's equivalent to the empty string.

```@example
using HTM  # hide

htm"<button disabled=$(true)>Can't click me</button>"
```

### Optional values

If an attribute value is nothing or missing, it's as if the attribute hadn't been specified.
If a data value is nothing or missing, nothing is embedded.

TODO: correct behavior for missing.

```@example
using HTM  # hide

htm"<button disabled=$(nothing)>Can click me</button>"
```

```@example
using HTM  # hide

htm"<span>There's no $(nothing) here.</span>"
```

```jldoctest
julia> htm"$(htm\"\")" === nothing  # It's nothings all the way down!
true
```

### Spread attributes

MAJOR TODO

### Node values

If an interpolated data value is a node, it is inserted into the result at the corresponding location.
So if you have a function that generates a node (say itself using HTM.jl), you can embed the result into another HTM.jl.

```@example
using HTM  # hide

emphasize(text) = htm"<em>$(text)</em>"

htm"<span>This is $(emphasize(\"really\")) important.</span>"
```

### Iterable values

You can interpolate iterables into data, too, even iterables of nodes.
This is useful for mapping data to content via `map`.
Typically, you should use html.fragment for the embedded expressions.

```@example
using HTM  # hide

colorscheme = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
               "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]

rows = map(enumerate(colorscheme)) do (i, color)
    htm"<tr>
        <td>$(i)</td>
        <td>$(color)</td>
        <td style=\"background: $(color);\"></td>
    </tr>"
end

htm"""<table>
    <thead><tr><th>#</th><th>Color</th><th>Swatch</th></tr></thead>
    <tbody>$(rows)</tbody>
</table>"""
```

```jldoctest
julia> htm"<span>It's as easy as $([1, 2, 3]).</span>"
<span>It&#39;s as easy as 123.</span>
```

### Errors on invalid bindings

TODO: this will probably be removed

HTM.jl tolerates malformed input--per the HTML5 specification--but it still tries to be helpful by throwing an error if you interpolate a value into an unexpected place.

TODO: this is different from htl

```@example
using HTM  # hide

tag = "button"

htm"<$(tag)>This does work!</$(tag)>"
```

## SVG

You can create contextual SVG fragments using HTM.jl, too.

```@example
using HTM  # hide

width, height = 100, 100
radius = 40
color = "red"

htm"<svg width=$(width) height=$(height)>
  $(htm\"<circle
            cx=$(width / 2)
            cy=$(height / 2)
            r=$radius
            fill=$color
         ></circle>\")
</svg>"
```

## CSS

### Inline styles

You can interpolate into a style attribute as a string, but use caution: automatic escaping will still allow you to set multiple style properties this way, or to generate invalid CSS.

```jldoctest
julia> htm"""<span style="background: $("yellow; font-style: italic");">It's yellow (and italic).</span>"""
<span style="background: yellow; font-style: italic;">It&#39;s yellow &#40;and italic&#41;.</span>
```

TODO: the following requires special treatment, doesn't currently work as indicated.

You can safely interpolate into style properties, too, by specifying the style attribute as a `Dict`:

```jldoctest
julia> htm"""<span style=$(Dict("background" => "yellow"))>It's all yellow!</span>"""
<span style="Dict{String, Any}(&#34;background&#34; =&#62; &#34;yellow&#34;)">It&#39;s all yellow&#33;</span>
```

### `style` tags

TODO

## JavaScript

### Function attributes

If an attribute value is a function, it is assigned as a property.
This can be used to register event listeners.

TODO: this does not quite work as said (expressions, not functions, are handled).

```@example
using HTM  # hide
using JSExpr

htm"""<button onclick=$(@js (() -> alert("Hello 🌍!"))())>Click me</button>"""
```

### `script` tags

```@example
using HTM  # hide
using JSExpr

sval = "Say \"Hello\"!";

# TODO: this requires not escaping script tags

htm"<script>$(@js begin
    @var x = $sval
    alert(x)
end)</script>"
```

```
<script>
    // Should be
    var x = "Say \"Hello\"!";
    alert(x);
</script>
```

## Components

Julia *already* has a component concept: it is called the display convention.
You just have to have `Base.show` overloaded for `text/html` (and maybe
`text/plain`).

Especifically, the way of doing components is through functions and
structures.
A function could work as follows:

```jldoctest
julia> mycomponent(name) = htm"<div>My name is $(name).</div>"
mycomponent (generic function with 1 method)

julia> const app = htm"$(mycomponent(\"John Doe\"))"
<div>My name is John Doe.</div>
```

For a structure, you would to overload `Base.show` for `text/html`:

```jldoctest
julia> struct Link{H,C}
           href::H
           children::C
       end

julia> Base.show(io::IO, mime::MIME"text/html", a::Link) =
           show(io, mime, htm"<a href=$(a.href)>$(a.children)</a>")

julia> htm"""<em>$(Link("http://bit.ly/htm-jl", "HTM.jl"))</em>"""
<em><a href="http://bit.ly/htm-jl">HTM.jl</a></em>
```

If your object is the single one parsed, `Base.show`  for `text/plain` will
be called.
You can adjust the printing in this case by overloading `Base.show` for this,
maybe falling back to the one above:

```jldoctest
julia> htm"""$(Link("http://bit.ly/htm-jl", "HTM.jl"))"""
Link{String, String}("http://bit.ly/htm-jl", "HTM.jl")

julia> Base.show(io::IO, mime::MIME"text/plain", a::Link) =
           show(io, MIME("text/html"), a)

julia> htm"""$(Link("http://example.com", "Some Text"))"""
<a href="http://example.com">Some Text</a>
```

## Guide roadmap

- [ ] Compare with Hyperscript.jl in the documentation.
- [ ] Using JSExpr.jl with HTM.jl
- [ ] Separate things in basics and advanced
