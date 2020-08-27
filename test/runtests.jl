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

    @testset "block invalid indicator" begin
        @test_throws ArgumentError block("", "fs_")  # Too many indicators
        @test_throws ArgumentError block("", "sf")   # Order matters
        @test_throws ArgumentError block("", "_s")   # Invalid style
        @test_throws ArgumentError block("", "f_")   # Invalid chomp
        @test_throws ArgumentError block("", "_")    # Invalid style/chomp
    end
end
