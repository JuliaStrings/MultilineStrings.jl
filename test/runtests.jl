using BlockScalars: @blk_str, block
using Test
using YAML: YAML

indent(str, n) = join(map(line -> (" " ^ n) * line, split(str, '\n')), '\n')

function yaml_block(str, block_scalar)
    yaml = "example: $block_scalar\n$(indent(str, 2))"
    YAML.load(yaml)["example"]
end

# https://yaml-multiline.info/
const TEXT = """
    Several lines of text,
    with some "quotes" of various 'types'
    and also two blank lines:


    plus another line at the end.


    """

const WHITESPACE = "a\nb\n c \nd\n"

# Validate `yaml_block` function
@assert yaml_block(TEXT, "|+") == TEXT
@assert yaml_block(TEXT, "|+") == TEXT

@testset "BlockScalars.jl" begin
    @testset "block: $name" for (name, str) in ("TEXT" => TEXT, "WHITESPACE" => WHITESPACE)
        @testset "literal" begin
            @test block(str, "lk") == yaml_block(str, "|+")
            @test block(str, "lc") == yaml_block(str, "|")
            @test block(str, "ls") == yaml_block(str, "|-")
        end

        @testset "folding" begin
            @test block(str, "fk") == yaml_block(str, ">+")
            @test block(str, "fc") == yaml_block(str, ">")
            @test block(str, "fs") == yaml_block(str, ">-")
        end

        @testset "default style" begin
            @test block(str, "k") == yaml_block(str, ">+")
            @test block(str, "c") == yaml_block(str, ">")
            @test block(str, "s") == yaml_block(str, ">-")
        end

        @testset "default chomp" begin
            @test block(str, "l") == yaml_block(str, "|-")
            @test block(str, "f") == yaml_block(str, ">-")
        end

        @testset "default" begin
            @test block(str) == yaml_block(str, ">-")
        end
    end
end
