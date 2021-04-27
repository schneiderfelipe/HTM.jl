# How it works

HyperscriptLiteral.jl was designed to do one thing: produce HTML.

Referencing the fantastically precise HTML5 spec, we built HyperscriptLiteral.jl.

Under the hood, HyperscriptLiteral.jl implements a subset of the HTML5 tokenizer state machine.
This allows it to distinguish between tags, attributes, and the like.
And so wherever an embedded expression occurs, it can be interpreted correctly.

Our approach is more formal (and, if you like, more precise) than using regular expressions to search for "attribute-like sequences" in markup.
And while our approach requires scanning the input, the state machine is pretty fast.

And unlike regular string interpolation, HyperscriptLiteral.jl directly creates content rather than reusable templates.
HyperscriptLiteral.jl is thus well-suited to reactive environments, where HTML is automatically generated when inputs change.

We also wanted to minimize new syntax.
We were inspired by HTM, but HTM emulates JSX--not HTML5--requiring closing tags for every element.

For a closer look at our implementation, please [view the source](https://github.com/schneiderfelipe/HyperscriptLiteral.jl) and let us know what you think! We welcome your contributions and bug reports on GitHub.

https://observablehq.com/@observablehq/htl
