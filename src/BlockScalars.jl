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

    if style == 'f'
        # The code below is equivalent to these two regexes:
        # ```
        # str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        # str = replace(str, r"(?<=\n)\n(?=\S)" => "")
        # ```

        b = IOBuffer()
        prev = curr = '\0'
        for next in str
            if curr == '\n' && !isspace(next)
                if prev == '\n'
                    # Skip
                elseif !isspace(prev)
                    write(b, ' ')
                else
                    write(b, curr)
                end
            elseif curr != '\0'
                write(b, curr)
            end

            prev = curr
            curr = next
        end

        write(b, curr)
        str = String(take!(b))
    elseif style != 'l'
        throw(ArgumentError("Unknown block style indicator: $(repr(style))"))
    end

    if chomp == 'c'
        str = rstrip(str, '\n') * '\n'
    elseif chomp == 's'
        str = rstrip(str, '\n')
    elseif chomp != 'k'
        throw(ArgumentError("Unknown block chomping indicator: $(repr(chomp))"))
    end

    return str
end

macro blk_str(str::AbstractString, suffix::AbstractString="")
    block(str, suffix)
end

end
