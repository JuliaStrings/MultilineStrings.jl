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

    out = IOBuffer()
    num_newlines = 0

    if style == 'f'
        # The code below is equivalent to these two regexes:
        # ```
        # str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        # str = replace(str, r"(?<=\n)\n(?=\S)" => "")
        # ```

        prev = curr = '\0'
        for next in str

            if curr == '\n'
                if !isspace(next)
                    if prev == '\n'
                        # Skip
                    elseif !isspace(prev)
                        write(out, ' ')
                    else
                        num_newlines += 1
                    end
                else
                    num_newlines += 1
                end
            elseif curr != '\0'
                if num_newlines > 0
                    write(out, "\n" ^ num_newlines)
                    num_newlines = 0
                end

                write(out, curr)
            end

            prev = curr
            curr = next
        end

        if curr == '\n'
            num_newlines += 1
        elseif curr != '\0'
            if num_newlines > 0
                write(out, "\n" ^ num_newlines)
                num_newlines = 0
            end

            write(out, curr)
        end
    elseif style == 'l'
        curr = '\0'
        for next in str
            if curr == '\n'
                num_newlines += 1
            elseif curr != '\0'
                if num_newlines > 0
                    write(out, "\n" ^ num_newlines)
                    num_newlines = 0
                end

                write(out, curr)
            end

            curr = next
        end

        if curr == '\n'
            num_newlines += 1
        elseif curr != '\0'
            if num_newlines > 0
                write(out, "\n" ^ num_newlines)
                num_newlines = 0
            end

            write(out, curr)
        end
    else
        throw(ArgumentError("Unknown block style indicator: $(repr(style))"))
    end

    if chomp == 'c'
        num_newlines > 0 && write(out, '\n')
    elseif chomp == 'k'
        write(out, "\n" ^ num_newlines)
    elseif chomp != 's'
        throw(ArgumentError("Unknown block chomping indicator: $(repr(chomp))"))
    end

    return String(take!(out))
end

macro blk_str(str::AbstractString, suffix::AbstractString="")
    block(str, suffix)
end

end
