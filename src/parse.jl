"""
Parse a tree.
"""
parse(data::AbstractString)::Node = first(parse!(Node(:dummy), data))

"""
Parse a tree by modifying the a dummy node.
"""
function parse!(parent::Node, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data))
    i > n && return parent, i

    if hasfinished(parent, data, i, n)
        return parent, nextind(data, i, length(endtag(parent)))
    elseif data[i] == '<'
        i = nextind(data, i)

        attrs = Pair{String,Any}[]

        haschildren = true
        if startswith(data[i:n], "!--")
            # A wild comment has appeared!
            tagname = :comment
            i = nextind(data, i, 3)
        else
            j = prevind(data, findnext('>', data, i))
            tagname = data[i:j]
            i = nextind(data, j, 2)

            if last(tagname) == '/'
                tagname = rstrip(tagname[1:prevind(tagname, end)])
                haschildren = false
            end

            k = findfirst(isspace, tagname)
            if !isnothing(k)
                # prevind/nextind are needed to support Unicode
                tagname, rest = tagname[1:prevind(tagname, k)], tagname[nextind(tagname, k):end]

                r, s, m = 1, 1, lastindex(rest)
                while s < m
                    @assert r <= s
                    if rest[s] == '='
                        key = rest[r:prevind(rest, s)]
                        r = s = nextind(rest, s)
                        if rest[r] == '"'
                            # We leave the quotation marks because an object will be parsed later
                            s = findnext('"', rest, nextind(rest, r))
                            push!(attrs, key => rest[r:s])
                        else
                            # No quotation mark
                            if rest[r] == '$'
                                # Step forward and ignore '$'
                                r = nextind(rest, r)
                            end
                            s = findnext(isspace, rest, r)  # TODO: we do not tolerate spaces between '=' and the value?
                            if isnothing(s)
                                # Last attribute
                                push!(attrs, key => rest[r:m])
                                break
                            end
                            push!(attrs, key => rest[r:prevind(rest, s)])
                        end
                        r = s = nextind(rest, s)
                    elseif isspace(rest[r])
                        if r < m
                            r = s = nextind(rest, r)
                        else
                            break
                        end
                    end
                    if s < m
                        s = nextind(rest, s)
                    else
                        break
                    end
                end
            end
        end

        child = Node(tagname, attrs=attrs)
        if haschildren
            child, i = parse!(child, data, i, n)
        end
        push!(children(parent), child)
    else
        j = findlimit(parent, data, i, n)

        text = data[i:j]
        i = nextind(data, i, length(text))

        text = replace(text, r"\s+" => ' ')

        isblank(text) || push!(children(parent), text)
    end

    return parse!(parent, data, i, n)
end

"""
Find the position where the content ends.
"""
function findlimit(::Node, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data))
    j = findnext('<', data, i)
    if !isnothing(j)
        return prevind(data, j)
    end
    return n
end
function findlimit(::Node{:comment}, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data))
    j = findnext("-->", data, i)
    if !isnothing(j)
        return prevind(data, first(j))
    end
    return n
end

"""
Check whether we have reached the end of the current tag.
"""
hasfinished(parent::Node, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data)) = startswith(data[i:n], endtag(parent))
hasfinished(parent::Node{:dummy}, data::AbstractString, i::Int=firstindex(data), n::Int=lastindex(data)) = false