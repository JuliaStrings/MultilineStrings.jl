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
        str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        str = replace(str, r"(?<=\S)\n(\n+)(?!$)" => s"\1")
    elseif style != 'l'
        throw(ArgumentError("Unknown block style indicator: $(repr(style))"))
    end

    if chomp == 'c'
        str = replace(str, r"\n+$" => "\n")
    elseif chomp == 's'
        str = replace(str, r"\n+$" => "")
    elseif chomp != 'k'
        throw(ArgumentError("Unknown block chomping indicator: $(repr(chomp))"))
    end

    return str
end

macro blk_str(str::AbstractString, suffix::AbstractString="")
    block(str, suffix)
end

end
