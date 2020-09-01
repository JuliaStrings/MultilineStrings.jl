module MultilineStrings

export @m_str

const ETX = '\x03'  # ASCII control character: End of Text
const DEFAULT_STYLE = :folded
const DEFAULT_CHOMP = :strip

"""
    multiline(str, style=$(repr(DEFAULT_STYLE)), chomp=$(repr(DEFAULT_CHOMP))) -> AbstractString

Create a multiline string according to the provided `style` and `chomp`. Works similarly to
YAML multiline strings (also known as block scalars).

# Arguments
- `str::AbstractString`: The multiline string to be processed

# Keywords
- `style::Symbol`: Replace newlines with spaces (`:folded`) or keep newlines (`:literal`)
- `chomp::Symbol`: No newlines at the end (`:strip`), single newline at the end (`:clip`),
  or keep all newlines from the end (`:keep`)
"""
function multiline(str::AbstractString; style=DEFAULT_STYLE, chomp=DEFAULT_CHOMP)
    multiline(str, style, chomp)
end

"""
    multiline(str, indicators) -> AbstractString

Revise a multiline string according to the provided style and chomp encoded in the
`indicators` string.

# Arguments
- `str::AbstractString`: The multiline string to be processed
- `indicators::AbstractString`: A terse string representing the style and chomp. Indicators
  can be either in letter-form or in YAML-form:

    - "fs" / ">-": folded and strip
    - "fc" / ">": folded and clip
    - "fk" / ">+": folded and keep
    - "ls" / "|-": literal and strip
    - "lc" / "|": literal and clip
    - "lk" / "|+": literal and keep
"""
function multiline(str::AbstractString, indicators::AbstractString)
    indicators_len = length(indicators)
    indicators_len > 2 && throw(ArgumentError("Too many indicators provided"))

    # Note: Using '\0` to indicate undefined
    yaml_chomp = false
    style_char, chomp_char = if indicators_len == 2
        indicators
    elseif indicators_len == 1
        ind = indicators[1]
        if ind in ('f', 'l')
            ind, '\0'
        elseif ind in ('>', '|')
            yaml_chomp = true
            ind, '\0'
        else
            '\0', ind
        end
    else
        '\0', '\0'
    end

    if style_char != '\0' && chomp_char != '\0' && isletter(style_char) ⊻ isletter(chomp_char)
        throw(ArgumentError("Can't mix YAML style block indicators with letter indicators"))
    end

    style = if style_char == 'f' || style_char == '>'
        :folded
    elseif style_char == 'l' || style_char == '|'
        :literal
    elseif style_char == '\0'
        DEFAULT_STYLE
    else
        throw(ArgumentError("Unknown style indicator: $(repr(style_char))"))
    end

    chomp = if chomp_char == 'c' || yaml_chomp
        :clip
    elseif chomp_char == 's' || chomp_char == '-'
        :strip
    elseif chomp_char == 'k' || chomp_char == '+'
        :keep
    elseif chomp_char == '\0'
        DEFAULT_CHOMP
    else
        throw(ArgumentError("Unknown chomping indicator: $(repr(chomp_char))"))
    end

    return multiline(str, style, chomp)
end

function multiline(str::AbstractString, style::Symbol, chomp::Symbol)
    # Append an additional, non-space, character to force one more iteration of the style
    # loop
    str *= ETX

    out = IOBuffer()
    num_newlines = 0  # The number of newlines at the end of the string
    prev = curr = '\0'

    # Replace newlines with spaces (folded)
    if style === :folded
        # The code below is equivalent to these two regexes (the non-regex code has much
        # better performance):
        # ```
        # str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        # str = replace(str, r"(?<=\n)\n(?=\S)" => "")
        # ```

        for next in str
            if curr == '\n'
                if !isspace(next) && next != ETX
                    if prev == '\n'
                        # Skip last newline in a sequence of sequential blank lines
                    elseif !isspace(prev)
                        # Replace a single newline with a space
                        write(out, ' ')
                    else
                        num_newlines += 1
                    end
                else
                    num_newlines += 1
                end
            elseif curr != '\0'
                # Insert newlines which were determined to not be at the end of the string
                if num_newlines > 0
                    write(out, "\n" ^ num_newlines)
                    num_newlines = 0
                end

                write(out, curr)
            end

            prev = curr
            curr = next
        end

    # Keep newlines (literal)
    elseif style === :literal
        for next in str
            if curr == '\n'
                num_newlines += 1
            elseif curr != '\0'
                # Insert newlines which were determined to not be at the end of the string
                if num_newlines > 0
                    write(out, "\n" ^ num_newlines)
                    num_newlines = 0
                end

                write(out, curr)
            end

            curr = next
        end
    else
        throw(ArgumentError("Unknown style indicator: $style"))
    end

    # Single newline at end (clip)
    if chomp === :clip
        num_newlines > 0 && write(out, '\n')

    # No newline at end (strip)
    elseif chomp === :strip
        # no-op

    # All newlines from end (keep)
    elseif chomp === :keep
        write(out, "\n" ^ num_newlines)
    else
        throw(ArgumentError("Unknown chomping indicator: $chomp"))
    end

    return String(take!(out))
end

"""
    @m_str -> String

Manipulate a multiline string literal according to a style and chomp indicator (provided
after the ending quote):

- Style indicator:
    - `f` replace newlines with spaces (folded, default)
    - `l` keep newlines (literal)
- Chomp indicator:
    - `s` no newlines at the end (strip, default)
    - `c` single newline at the end (clip)
    - `k` keep all newlines from the end (keep)

If both a style and chomp indicator is provided the style indicator must be specified first.

Note string interpolation is still respected any newlines added from interpolation will be
also be processed.

# Examples

```jldoctest; setup = :(using MultilineStrings)
julia> m\"\"\"
       A string written
       over multiple lines
       \"\"\"
"A string written over multiple lines"
```
"""
macro m_str(str::AbstractString, indicators::AbstractString="")
    parsed = interpolate(str)

    # When no string interpolation needs to take place we can just process the multiline
    # string during parse time. If string interpolation needs to take place we'll evaluate
    # the multiline string at runtime so that we can process after interpolation has taken
    # place.
    result = if parsed isa String
        multiline(unescape_string(parsed), indicators)
    else
        Expr(:call, :(MultilineStrings.multiline), parsed, indicators)
    end

    return esc(result)
end

function interpolate(str::AbstractString)
    components = []
    start = 1
    lastind = lastindex(str)

    state = iterate(str)
    while state !== nothing
        c, i = state

        if c == '$'
            ending = prevind(str, i, 2)
            start <= ending && push!(components, SubString(str, start, ending))

            expr, i = Meta.parse(str, i; greedy=false)
            push!(components, expr)
            start = i
        end

        state = iterate(str, i)
    end

    # When interpolation isn't used we can just return the original string
    start == 1 && return str

    ending = lastind
    start <= ending && push!(components, SubString(str, start, ending))

    return Expr(:string, components...)
end

end