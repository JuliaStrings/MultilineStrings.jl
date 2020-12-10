"""
    indent(str::AbstractString, n::Int)

Indent each non-blank line by `n` spaces.

# Examples
```jldoctest; setup = :(using MultilineStrings)
julia> indent("a\\nb", 4)
"    a\\n    b"

julia> indent("  a\\n  \\n  b", 2)
"    a\\n  \\n    b"
```

See also `Base.unintent` and `Base.indentation`.
"""
function indent(str::AbstractString, n::Int)
    n == 0 && return str
    # Note: this loses the type of the original string
    buf = IOBuffer(sizehint=sizeof(str))
    indent_str = ' ' ^ n

    line_start = firstindex(str)
    blank_line = true
    for (i, ch) in enumerate(str)
        if ch == '\n'
            !blank_line && print(buf, indent_str)
            print(buf, SubString(str, line_start, i))
            line_start = nextind(str, i)
            blank_line = true
        elseif blank_line && !isspace(ch)
            blank_line = false
        end
    end

    # Last line of string that doesn't contain a newline
    !blank_line && print(buf, indent_str)
    print(buf, SubString(str, line_start, lastindex(str)))

    String(take!(buf))
end
