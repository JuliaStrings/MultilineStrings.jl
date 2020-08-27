module BlockScalars

export @blk_str


const DEFAULT_STYLE = 'f'
const DEFAULT_CHOMP = 's'

function block(str::AbstractString, block_scalar::AbstractString="")
    block_scalar_len = length(block_scalar)
    block_scalar_len > 2 && throw(ArgumentError("Too many indicators provided"))

    style, chomp = if block_scalar_len == 2
        block_scalar
    elseif block_scalar_len == 1
        ind = block_scalar[1]
        if ind in "fl"
            ind, DEFAULT_CHOMP
        else
            DEFAULT_STYLE, ind
        end
    else
        DEFAULT_STYLE, DEFAULT_CHOMP
    end

    # Append an additional character to force one more iteration of the style loop
    str *= '\0'

    out = IOBuffer()
    num_newlines = 0  # The number of newlines at the end of the string
    prev = curr = '\0'

    # Replace newlines with spaces (folded)
    if style == 'f'
        # The code below is equivalent to these two regexes:
        # ```
        # str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        # str = replace(str, r"(?<=\n)\n(?=\S)" => "")
        # ```

        for next in str
            if curr == '\n'
                if !isspace(next)
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
    elseif style == 'l'
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
        throw(ArgumentError("Unknown block style indicator: $(repr(style))"))
    end

    # Single newline at end (clip)
    if chomp == 'c'
        num_newlines > 0 && write(out, '\n')

    # No newline at end (strip)
    elseif chomp == 's'
        # no-op

    # All newlines from end (keep)
    elseif chomp == 'k'
        write(out, "\n" ^ num_newlines)
    else
        throw(ArgumentError("Unknown block chomping indicator: $(repr(chomp))"))
    end

    return String(take!(out))
end

macro blk_str(str::AbstractString, suffix::AbstractString="")
    block(str, suffix)
end

end
