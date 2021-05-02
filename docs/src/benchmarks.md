# Benchmarks

This is a small suite of benchmarks for tracking the performance of the
package, as well as estimating the overhead of it in comparison with the
direct usage of the default backend
([Hyperscript.jl](https://github.com/yurivish/Hyperscript.jl)).
Both creation and parse times are measured.

```@setup benchmarks
include("../../benchmark/benchmarks.jl")
results = run(suite)
groups = ["Parse", "Create", "Backend"]
```

!!! info
    The benchmark tables are automatically build with this documentation
    using HTM.jl itself.
    The code for generating the tables is shown below, as it is useful as an
    usage example of the library, but please take a look at the
    [benchmark code](https://github.com/schneiderfelipe/HTM.jl/blob/master/benchmark/benchmarks.jl)
    and
    [help improving it](https://github.com/schneiderfelipe/HTM.jl/issues). 🙏

You can sort rows by clicking on column headers (thanks to
[`sorttable.js`](https://www.kryogenix.org/code/browser/sorttable/)).

```@example benchmarks
htm"<script src=https://www.kryogenix.org/code/browser/sorttable/sorttable.js />"  # hide
```

## Runtime and garbage collection

```@example benchmarks
header = htm"""<tr>
    <th scope=col>Code</th>
    $(htm"<th scope=col>$(name) time</th>
          <th scope=col>$(name) GC</th>" for name in groups)
</tr>"""

rows = map(results) do (code, result)
    htm"""<tr>
        <th scope=row><code>$(code)</code></th>
        $(map(["parser", "create", "direct"]) do name
            data = median(result[name])
            htm"<td>$(round(data.time / 1000, digits=2))  </td>
                <td>$(round(data.gctime / 1000, digits=2))</td>"
        end)
    </tr>"""
end

htm"<table class=sortable>
    <caption>Median run- and garbage collection times (in µs)</caption>
    <thead>$(header)</thead>
    <tbody>$(rows)</tbody>
</table>"
```

## Memory usage and number of allocations

```@example benchmarks
header = htm"""<tr>
    <th scope=col>Code</th>
    $(htm"<th scope=col>$(name) mem.</th>
          <th scope=col>$(name) alloc.</th>" for name in groups)
</tr>"""

rows = map(results) do (code, result)
    htm"""<tr>
        <th scope=row><code>$(code)</code></th>
        $(map(["parser", "create", "direct"]) do name
            data = median(result[name])
            htm"<td>$(round(data.memory / 1000, digits=2))</td>
                <td>$(data.allocs)</td>"
        end)
    </tr>"""
end

htm"<table class=sortable>
    <caption>Median memory usage (in kB) and number of allocations</caption>
    <thead>$(header)</thead>
    <tbody>$(rows)</tbody>
</table>"
```
