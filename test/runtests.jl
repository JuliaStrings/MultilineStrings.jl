using BlockScalars: @blk_str, block
using Test
using YAML: YAML

indent(str, n) = join(map(line -> (" " ^ n) * line, split(str, '\n')), '\n')

function yaml_block(str, block_scalar)
    yaml = "example: $block_scalar\n$(indent(str, 2))"
    YAML.load(yaml)["example"]
end

# https://yaml-multiline.info/
const TEST_STRINGS = [
    "paragraph" => """
        Several lines of text,
        with some "quotes" of various 'types'
        and also two blank lines:


        plus another line at the end.


        """,
    "whitespace" => "a\nb\n c \nd\n",
    "no ending newline" => "foo",
]

# Validate `yaml_block` function
for (test, str) in TEST_STRINGS
    @assert yaml_block(str, "|+") == str
end

@testset "BlockScalars.jl" begin
    @testset "block: $test" for (test, str) in TEST_STRINGS
        @testset "literal" begin
            @test block(str, :literal, :keep) == yaml_block(str, "|+")
            @test block(str, :literal, :clip) == yaml_block(str, "|")
            @test block(str, :literal, :strip) == yaml_block(str, "|-")
        end

        @testset "folding" begin
            @test block(str, :folded, :keep) == yaml_block(str, ">+")
            @test block(str, :folded, :clip) == yaml_block(str, ">")
            @test block(str, :folded, :strip) == yaml_block(str, ">-")
        end

        @testset "default chomp" begin
            @test block(str, :literal) == yaml_block(str, "|-")
            @test block(str, :folded) == yaml_block(str, ">-")
        end

        @testset "default style" begin
            @test block(str, chomp=:keep) == yaml_block(str, ">+")
            @test block(str, chomp=:clip) == yaml_block(str, ">")
            @test block(str, chomp=:strip) == yaml_block(str, ">-")
        end

        @testset "default" begin
            @test block(str) == yaml_block(str, ">-")
        end
    end

    # @testset "block invalid indicator" begin
    #     @test_throws ArgumentError block("", "fs_")  # Too many indicators
    #     @test_throws ArgumentError block("", "sf")   # Order matters
    #     @test_throws ArgumentError block("", "_s")   # Invalid style
    #     @test_throws ArgumentError block("", "f_")   # Invalid chomp
    #     @test_throws ArgumentError block("", "_")    # Invalid style/chomp
    # end

    @testset "@blk_str" begin
        @testset "invalid indicators" begin
            @test_throws LoadError macroexpand(@__MODULE__, :(@blk_str "" "fs_"))  # Too many indicators
            @test_throws LoadError macroexpand(@__MODULE__, :(@blk_str "" "sf"))  # Order matters
            @test_throws LoadError macroexpand(@__MODULE__, :(@blk_str "" "_s"))  # Invalid style
            @test_throws LoadError macroexpand(@__MODULE__, :(@blk_str "" "f_"))  # Invalid chomp
            @test_throws LoadError macroexpand(@__MODULE__, :(@blk_str "" "_"))   # Invalid style/chomp
        end
    end
end
