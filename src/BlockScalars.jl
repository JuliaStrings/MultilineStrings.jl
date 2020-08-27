module BlockScalars

export @blk_str

const DEFAULT_BLOCK_SCALAR = "fs"

function block(str::AbstractString, block_scalar::AbstractString=DEFAULT_BLOCK_SCALAR)
    style_indicators = intersect(block_scalar, "fl")
    chomp_indicators = intersect(block_scalar, "csk")

    if length(style_indicators) == 0
        style_indicator = 'f'
    elseif length(style_indicators) == 1
        style_indicator = first(style_indicators)
    else
        throw(ArgumentError("Only one block style indicators can be provided"))
    end

    if length(chomp_indicators) == 0
        chomp_indicator = 's'
    elseif length(chomp_indicators) == 1
        chomp_indicator = first(chomp_indicators)
    else
        throw(ArgumentError("Only one block chomp indicators can be provided"))
    end

    if style_indicator == 'f'
        str = replace(str, r"(?<=\S)\n(?=\S)" => " ")
        str = replace(str, r"(?<=\S)\n(\n+)(?!$)" => s"\1")
    end

    if chomp_indicator == 'c'
        str = replace(str, r"\n+$" => "\n")
    elseif chomp_indicator == 's'
        str = replace(str, r"\n+$" => "")
    end

    return str
end

macro blk_str(str::AbstractString, suffix::AbstractString=DEFAULT_BLOCK_SCALAR)
    block(str, suffix)
end

end
