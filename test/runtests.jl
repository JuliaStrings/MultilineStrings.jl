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
        expected_lk = yaml_block(str, "|+")
        expected_lc = yaml_block(str, "|")
        expected_ls = yaml_block(str, "|-")

        expected_fk = yaml_block(str, ">+")
        expected_fc = yaml_block(str, ">")
        expected_fs = yaml_block(str, ">-")

        @testset "literal" begin
            @test block(str, :literal, :keep) == expected_lk
            @test block(str, :literal, :clip) == expected_lc
            @test block(str, :literal, :strip) == expected_ls

            @test block(str, style=:literal, chomp=:keep) == expected_lk
            @test block(str, style=:literal, chomp=:clip) == expected_lc
            @test block(str, style=:literal, chomp=:strip) == expected_ls
        end

        @testset "folding" begin
            @test block(str, :folded, :keep) == expected_fk
            @test block(str, :folded, :clip) == expected_fc
            @test block(str, :folded, :strip) == expected_fs

            @test block(str, style=:folded, chomp=:keep) == expected_fk
            @test block(str, style=:folded, chomp=:clip) == expected_fc
            @test block(str, style=:folded, chomp=:strip) == expected_fs
        end

        @testset "default chomp" begin
            @test block(str, :literal) == expected_ls
            @test block(str, :folded) == expected_fs

            @test block(str, style=:literal) == expected_ls
            @test block(str, style=:folded) == expected_fs
        end

        @testset "default style" begin
            @test block(str, chomp=:keep) == expected_fk
            @test block(str, chomp=:clip) == expected_fc
            @test block(str, chomp=:strip) == expected_fs
        end

        @testset "default style/chomp" begin
            @test block(str) == expected_fs
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
