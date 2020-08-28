module BlockScalars

export @blk_str

const ETX = '\x03'  # ASCII control character: End of Text
const DEFAULT_STYLE = :folded
const DEFAULT_CHOMP = :strip

function block(str::AbstractString; style=DEFAULT_STYLE, chomp=DEFAULT_CHOMP)
    block(str, style, chomp)
end

function block(str::AbstractString, indicators::AbstractString)
    indicators_len = length(indicators)
    indicators_len > 2 && throw(ArgumentError("Too many indicators provided"))

    # Note: Using '\0` to indicate undefined
    style_char, chomp_char = if indicators_len == 2
        indicators
    elseif indicators_len == 1
        ind = indicators[1]
        if ind in "fl"
            ind, '\0'
        else
            '\0', ind
        end
    else
        '\0', '\0'
    end

    style = if style_char == 'f'
        :folded
    elseif style_char == 'l'
        :literal
    elseif style_char == '\0'
        DEFAULT_STYLE
    else
        throw(ArgumentError("Unknown block style indicator: $(repr(style_char))"))
    end

    chomp = if chomp_char == 'c'
        :clip
    elseif chomp_char == 's'
        :strip
    elseif chomp_char == 'k'
        :keep
    elseif chomp_char == '\0'
        DEFAULT_CHOMP
    else
        throw(ArgumentError("Unknown block chomping indicator: $(repr(chomp_char))"))
    end

    return block(str, style, chomp)
end

function block(str::AbstractString, style::Symbol, chomp::Symbol=DEFAULT_CHOMP)
    # Append an additional, non-space, character to force one more iteration of the style
    # loop
    str *= ETX

    out = IOBuffer()
    num_newlines = 0  # The number of newlines at the end of the string
    prev = curr = '\0'

    # Replace newlines with spaces (folded)
    if style === :folded
        # The code below is equivalent to these two regexes:
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
        throw(ArgumentError("Unknown block style indicator: $style"))
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
        throw(ArgumentError("Unknown block chomping indicator: $chomp"))
    end

    return String(take!(out))
end

macro blk_str(str::AbstractString, indicators::AbstractString="")
    return block(str, indicators)
end

end
