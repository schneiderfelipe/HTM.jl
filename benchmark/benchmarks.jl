using BenchmarkTools
using Hyperscript

using HTM

# Define a parent BenchmarkGroup to contain the suite
suite = BenchmarkGroup()

# --- Features ---

suite[raw"<div $(attrs)></div>"] = BenchmarkGroup(["spread-attrs", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
attrs = Dict(:class => "fruit")
suite[raw"<div $(attrs)></div>"]["direct"] = @benchmarkable m("div"; attrs...)
suite[raw"<div $(attrs)></div>"]["create"] = @benchmarkable htm"<div $(attrs)></div>"
suite[raw"<div $(attrs)></div>"]["parser"] = @benchmarkable HTM.parse(raw"<div $(attrs)></div>")

suite[raw"<div />"] = BenchmarkGroup(["self-closing-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div />"]["direct"] = @benchmarkable m("div")
suite[raw"<div />"]["create"] = @benchmarkable htm"<div />"
suite[raw"<div />"]["parser"] = @benchmarkable HTM.parse(raw"<div />")

suite[raw"<div /><div />"] = BenchmarkGroup(["fragments"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div /><div />"]["direct"] = @benchmarkable (m("div"), m("div"))
suite[raw"<div /><div />"]["create"] = @benchmarkable htm"<div /><div />"
suite[raw"<div /><div />"]["parser"] = @benchmarkable HTM.parse(raw"<div /><div />")

suite[raw"<div>$(hidefruit || '🍍')</div>"] = BenchmarkGroup(["short-circuit", "child-interps", "has-children", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
hidefruit = false
suite[raw"<div>$(hidefruit || '🍍')</div>"]["direct"] = @benchmarkable m("div", hidefruit || '🍍')
suite[raw"<div>$(hidefruit || '🍍')</div>"]["create"] = @benchmarkable htm"<div>$(hidefruit || '🍍')</div>"
suite[raw"<div>$(hidefruit || '🍍')</div>"]["parser"] = @benchmarkable HTM.parse(raw"<div>$(hidefruit || '🍍')</div>")

suite[raw"<div draggable />"] = BenchmarkGroup(["optional-attrs", "self-closing-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div draggable />"]["direct"] = @benchmarkable m("div", draggable=nothing)
suite[raw"<div draggable />"]["create"] = @benchmarkable htm"<div draggable />"
suite[raw"<div draggable />"]["parser"] = @benchmarkable HTM.parse(raw"<div draggable />")

suite[raw"<div draggable=$(true) />"] = BenchmarkGroup(["boolean-attrs", "attr-interps", "self-closing-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
draggable = true
suite[raw"<div draggable=$(true) />"]["direct"] = @benchmarkable draggable ? m("div", draggable=nothing) : m("div")
suite[raw"<div draggable=$(true) />"]["create"] = @benchmarkable htm"<div draggable=$(true) />"
suite[raw"<div draggable=$(true) />"]["parser"] = @benchmarkable HTM.parse(raw"<div draggable=$(true) />")

suite[raw"<div class=fruit></div>"] = BenchmarkGroup(["optional-quotes", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div class=fruit></div>"]["direct"] = @benchmarkable m("div", class="fruit")
suite[raw"<div class=fruit></div>"]["create"] = @benchmarkable htm"<div class=fruit></div>"
suite[raw"<div class=fruit></div>"]["parser"] = @benchmarkable HTM.parse(raw"<div class=fruit></div>")

suite[raw"<div style=$(style)></div>"] = BenchmarkGroup(["spread-styles", "attr-interps", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
style = Dict(:background => "orange")
suite[raw"<div style=$(style)></div>"]["direct"] = @benchmarkable m("div", style=join(("$(k):$(v)" for (k, v) in style), ';'))
suite[raw"<div style=$(style)></div>"]["create"] = @benchmarkable htm"<div style=$(style)></div>"
suite[raw"<div style=$(style)></div>"]["parser"] = @benchmarkable HTM.parse(raw"<div style=$(style)></div>")

suite[raw"<div>🍍<//>"] = BenchmarkGroup(["universal-end-tags", "has-children"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div>🍍<//>"]["direct"] = @benchmarkable m("div", "🍍")
suite[raw"<div>🍍<//>"]["create"] = @benchmarkable htm"<div>🍍<//>"
suite[raw"<div>🍍<//>"]["parser"] = @benchmarkable HTM.parse(raw"<div>🍍<//>")

suite[raw"<div><!-- 🍌 --></div>"] = BenchmarkGroup(["html-comment", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div><!-- 🍌 --></div>"]["direct"] = @benchmarkable m("div")
suite[raw"<div><!-- 🍌 --></div>"]["create"] = @benchmarkable htm"<div><!-- 🍌 --></div>"
suite[raw"<div><!-- 🍌 --></div>"]["parser"] = @benchmarkable HTM.parse(raw"<div><!-- 🍌 --></div>")

# --- Others ---

suite[raw"<div class=fruit>🍍</div>"] = BenchmarkGroup(["optional-quotes", "has-attrs", "has-children", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
suite[raw"<div class=fruit>🍍</div>"]["direct"] = @benchmarkable m("div", class="fruit", "🍍")
suite[raw"<div class=fruit>🍍</div>"]["create"] = @benchmarkable htm"<div class=fruit>🍍</div>"
suite[raw"<div class=fruit>🍍</div>"]["parser"] = @benchmarkable HTM.parse(raw"<div class=fruit>🍍</div>")

suite[raw"<div id=$(id)>$(content)</div>"] = BenchmarkGroup(["attr-interps", "child-interps", "has-children", "optional-quotes", "end-tags"],
    "direct" => BenchmarkGroup([]),
    "create" => BenchmarkGroup([]),
    "parser" => BenchmarkGroup([]),
)
id = 23
content = "Hello HTM.jl🍍!"
suite[raw"<div id=$(id)>$(content)</div>"]["direct"] = @benchmarkable m("div", id=id, content)
suite[raw"<div id=$(id)>$(content)</div>"]["create"] = @benchmarkable htm"<div id=$(id)>$(content)</div>"
suite[raw"<div id=$(id)>$(content)</div>"]["parser"] = @benchmarkable HTM.parse(raw"<div id=$(id)>$(content)</div>")

# TODO: component concept through Julia's display system
# TODO: some other ideas from:
# - <https://github.com/aminya/AcuteML.jl/blob/master/benchmark/bench.jl>
# - <https://codesandbox.io/embed/htm-3-caching-demo-4dx94>

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# the benchmark parameters. Reusing cached parameters is faster and more reliable
# than re-tuning `suite` every time the file is included.
paramspath = joinpath(dirname(@__FILE__), "params.json")
if isfile(paramspath)
    loadparams!(suite, BenchmarkTools.load(paramspath)[1], :evals);
else
    tune!(suite)
    BenchmarkTools.save(paramspath, params(suite));
end
