```@meta
DocTestSetup = quote
    using HTM

    struct Link{H,C}
        href::H
        children::C
    end
    Base.show(io::IO, m::MIME"text/html", a::Link) = show(io, m, htm"<a href=$(a.href)>$(a.children)</a>")
end
```

# Advanced usage

## Short circuit rendering

This is a
[common Julia idiom](https://docs.julialang.org/en/v1/manual/control-flow/#Short-Circuit-Evaluation)
that is also a
[common JSX idiom](https://reactjs.org/docs/conditional-rendering.html#inline-if-with-logical--operator):

```jldoctest
julia> hidefruit = false
false

julia> htm"<div>$(hidefruit || '🍍')</div>"
<div>🍍</div>
```

## Classes

If you give a vector to a `class` attribute, it will be properly set:

```jldoctest
julia> using HTM  # hide

julia> class = ["fruit", "sour", "green", "sour"];

julia> htm"<p class=$(class)>🥝</p>"
<p class="fruit sour green ">🥝</p>
```

## Errors on invalid bindings

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

width, height = 160, 160
radius = 40
points = [100     0  ;
          129.4  59.5;
          195.1  69.1;
          147.6 115.5;
          158.8 180.9;
          100   150  ;
           41.2 180.9;
           52.4 115.5;
            4.9  69.1;
           70.6  59.5]'
points .-= sum(points, dims=2) / 10
points .*= 15 / radius
points .+= [width / 2, height / 2] .- [0.03radius, 0.95radius]

htm"""<svg width=$(width) height=$(height) style="transform: rotate(-10deg)">
    <polygon
        points=$(join(points, ','))
        fill=green
    />
    <ellipse
        cx=$(width / 2) cy=$(height / 2)
        ry=$(radius) rx=$(0.8radius)
        fill=orange
    />
</svg>"""
```

## CSS

TODO: can we support scoped styles a la https://lit.dev/ and Hyperscript.jl?

### Inline styles

You can interpolate strings into aa attribute such as `style`, but use
caution: automatic escaping can lead to undesirable results such as invalid
CSS or assigning multiple CSS properties simultaneously:

```@example
using HTM  # hide

background = "orange; font-style: italic"

htm"<p>I'm <span style=\"background: $(background)\">orange (and italic)</span>.</p>"
```

The alternative is to specify the `style` attribute as a dictionary as well:

```@example
using HTM  # hide

style = Dict(
    "background" => "orange",
    "font-style" => "italic",
)

htm"<p>I'm <span style=$(style)>orange (and italic)</span>.</p>"
```

### `style` tags

TODO

## JavaScript

### Function attributes

If an attribute value is a function, it is assigned as an event listener.
This can be used to register event listeners.

TODO: this does not quite work as said (expressions, not functions, are handled).

Event listeners implemented as closures through JSExpr.jl,

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

In cases where it is not possible to interpolate safely, namely with script and style elements where the interpolated value contains the corresponding end-tag, an error is thrown.

```jldoctest
julia> htm"<script>$(\"</script>\")</script>"  # BUG: not what should happen
<script>&#60;/script&#62;</script>
```

## Extending HTM.jl through components

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

julia> Base.show(io::IO, m::MIME"text/html", a::Link) =
           show(io, m, htm"<a href=$(a.href)>$(a.children)</a>")

julia> htm"""<em>$(Link("http://bit.ly/htm-jl", "🥝 HTM.jl"))</em>"""
<em><a href="http://bit.ly/htm-jl">🥝 HTM.jl</a></em>
```

If your object is the single one parsed, `Base.show`  for `text/plain` will
be called.
You can adjust the printing in this case by overloading `Base.show` for this,
maybe falling back to the one above:

```jldoctest
julia> htm"""$(Link("http://bit.ly/htm-jl", "HTM.jl"))"""
Link{String, String}("http://bit.ly/htm-jl", "HTM.jl")

julia> Base.show(io::IO, ::MIME"text/plain", a::Link) =
           show(io, MIME("text/html"), a)

julia> htm"""$(Link("http://example.com", "Some Text"))"""
<a href="http://example.com">Some Text</a>
```



```
julia> box(content) = htm"<div id=$(rand(1:100))>$(content)</div>"
box (generic function with 1 method)

julia> app() = htm"""<body>
           $(map([1,2,3]) do n
               box("$n fast $n furious")
           end)
       </body>"""
app (generic function with 1 method)

julia> app()
<body>
    <div id="27">
        1 fast 1 furious
    </div>
    <div id="1">
        2 fast 2 furious
    </div>
    <div id="14">
        3 fast 3 furious
    </div>
</body>
```




As an alternative, you can redefine the [`HTM.render`](@ref) function.
This should only be used if the alternative above is not enough, as this is
not as general.

HTM defines the HTM.render function which can be extended to render any Julia
type into the DOM.
Think of it as a better version of `Base.show(io::IO, m::MIME"text/html", x)`
(where the output is a tree of Node's instead of an HTML string).

 is the primary method of extending HTM.jl
and providing interoperability between HTM.jl and other libraries.
For example, one could define a custom method to render a `Fruit` type.

Suppose we want to teach HTM.jl how to render our to-do list type.
For a `TodoItem`, we would do:

```@example todo
using HTM

struct TodoItem
    description::String
    done::Bool
end

function HTM.render(todoitem::TodoItem)
    style = Dict("display" => "flex", "flex-direction" => "horizontal")
    return htm"<div class=todo-item style=$(style)>
        <input type=checkbox checked=$(todoitem.done) />
        $(todoitem.description)
    </div>"
end
```

For the entire `TodoList`, we would do:

```@example todo
struct TodoList
    title::String
    items::Vector{TodoItem}
end

function HTM.render(list::TodoList)
    return htm"<div>
        <h2>$(list.title)</h2>
        <div class=todo-list>$(list.items)</div>
    </div>"
end
```

!!! note
    Observe that there's no need to recursively call `HTM.render` from inside
    `HTM.render`, HTM.jl does that for you.

We would then use as follows:

```@exampĺe todo
todos = TodoList(
    "My todo list",
    [
        TodoItem("Make my first HTM.jl widget", true),
        TodoItem("Make a pie", false),
    ],
)

htm"$(todos)"
```



### True web components

Future.
[See here](https://developer.mozilla.org/en-US/docs/Web/Web_Components).
Requires generating JavaScript (we should probably inject a single script tag
per call at the end, which means we might need to keep track of tag ids if
they are not given: use UUIDs? this probably has something to do with
[how react works](https://javascript.plainenglish.io/how-react-works-under-the-hood-277356c95e3d)).
Requires declarative
[event listeners](https://developer.mozilla.org/pt-BR/docs/Learn/JavaScript/Building_blocks/Events).
I want Julia functions as event listeners, can we do that with JSExpr?

[I want Lit-like syntax](https://lit.dev/tutorial/).

```julia-repl
julia> qs = @js document.querySelector("button")
JSString("document.querySelector(\"button\")")

julia> @js $(qs).addEventListener("click", $(f))
JSString("document.querySelector(\"button\").addEventListener(\"click\",function f(x){x+=1; document.querySelector(\"#root\"); return y={\"foo\":\"bar\"}})")
```

How do I interpolate JavaScript instead of Julia code?
What if I want to disable a button based on a JavaScript variable?
That would require adding an "event listener to the variable", a
JavaScript-side reactivity.
Can I wrap Julia variables in an object such that this "simply works"?
Can we use observable objects for that?

We would need to do the following (a JavaScript generator/simplifier):
- As we parse, we generate appropriate JavaScript code (to be inserted in a
script tag).
- JavaScript code from the children will be concatenated to their parents,
such that only a single script tag remains; since they won't talk to each
other, identifying elements in the tree would have to be descentralized, this
is probably a nice job for UUIDs.
- Since this would have to work with any backend, we would have to softwrap
stuff (an object with a child that behaves exactly like it); this adds the
bonus of being able to lazily evaluate create_element upon render/show.

In the future, the same thing as above could be done with style tags.

IDEA: Julia -> JavaScript IS your transpiler.
See <https://dev.to/samholmes/reactive-programming-in-javascript-141o> and
<https://dev.to/samholmes/the-reactor-pattern-80b>.

Sidenote: [Observables.jl](https://juliagizmos.github.io/Observables.jl/latest/).

## Backends

Just like `htm`, HTM.jl is a generic library.
This means it can "compile" to anything by redefining
the `create_element(tag, attrs, children...)` function (which produces Hyperscript.jl objects by
default).
The function can actually return anything--HTM.jl never looks at the return
value.

```jldoctest
julia> typeof(htm"<div />")  # Hyperscript object!
Hyperscript.Node{Hyperscript.HTMLSVG}
```

Here's an example of `create_element()` that returns a tuple:

```julia-repl
julia> HTM.create_element(tag, attrs, children...) = (tag, attrs, children)
```

Now the `@htm_str` macro can be used to produce objects in the format above:

```julia-repl
julia> htm"<h1 id=hello>Hello world!</h1>"
("h1", Dict{String, Any}("id" => "hello"), (("Hello world!",),))
```

If the input has multiple elements at the root level, the output is an array
of `create_element` results:

```julia-repl
julia> htm"""
           <h1 id=hello>Hello</h1>
           <div class=world>World!</div>
       """
(("h1", Dict{String, Any}("id" => "hello"), (("Hello",),)), ("div", Dict{String, Any}("class" => "world"), (("World!",),)))
```

A design decision was made such that the returned iterable is mutable.




```julia-repl
julia> using HTM, WebIO

julia> HTM.create_element(tag, attrs, children...) =
           WebIO.Node(tag, children, attrs)

julia> x = htm"<div id=$(rand(1:100)) />"
(div
  ((),)
  Dict{String, Any}("id" => 48))

julia> dump(x, maxdepth=1)
Node{WebIO.DOM}
  instanceof: WebIO.DOM
  children: FunctionalCollections.PersistentVector{Any}
  props: Dict{Symbol, Any}
```









## Guide roadmap

- [ ] Compare with Hyperscript.jl in the documentation.
- [ ] Using JSExpr.jl with HTM.jl
- [ ] How do I use HTM.jl together with [Mux.jl](https://github.com/JuliaWeb/Mux.jl)?
