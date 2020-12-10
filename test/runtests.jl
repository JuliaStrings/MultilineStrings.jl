using Documenter: doctest
using MultilineStrings
using MultilineStrings: MultilineStrings, @m_str, indent, interpolate, multiline
using Test
using YAML: YAML

function yaml_block(str, block_scalar)
    yaml = "example: $block_scalar\n$(indent(str, 2))"
    YAML.load(yaml)["example"]
end

const TEST_STRINGS = [
    # Modified example from: https://yaml-multiline.info/
    "yaml-multiline" => """
        Several lines of text,
        with some "quotes" of various 'types'
        and also two blank lines:


        plus another line at the end.


        """,
    "whitespace" => "a\nb\n c \nd\n",
    "no ending newline" => "foo",
    "starting newline" => "\nbar",
]

# Validate `yaml_block` function
for (test, str) in TEST_STRINGS
    @assert yaml_block(str, "|+") == str
end

@testset "MultilineStrings.jl" begin
    @testset "multiline" begin
        @testset "string: $test" for (test, str) in TEST_STRINGS
            expected_lk = yaml_block(str, "|+")
            expected_lc = yaml_block(str, "|")
            expected_ls = yaml_block(str, "|-")

            expected_fk = yaml_block(str, ">+")
            expected_fc = yaml_block(str, ">")
            expected_fs = yaml_block(str, ">-")

            @testset "literal" begin
                @test multiline(str, :literal, :keep) == expected_lk
                @test multiline(str, :literal, :clip) == expected_lc
                @test multiline(str, :literal, :strip) == expected_ls

                @test multiline(str, style=:literal, chomp=:keep) == expected_lk
                @test multiline(str, style=:literal, chomp=:clip) == expected_lc
                @test multiline(str, style=:literal, chomp=:strip) == expected_ls

                @test multiline(str, "lk") == expected_lk
                @test multiline(str, "lc") == expected_lc
                @test multiline(str, "ls") == expected_ls

                @test multiline(str, "|+") == expected_lk
                @test multiline(str, "|-") == expected_ls
            end

            @testset "folding" begin
                @test multiline(str, :folded, :keep) == expected_fk
                @test multiline(str, :folded, :clip) == expected_fc
                @test multiline(str, :folded, :strip) == expected_fs

                @test multiline(str, style=:folded, chomp=:keep) == expected_fk
                @test multiline(str, style=:folded, chomp=:clip) == expected_fc
                @test multiline(str, style=:folded, chomp=:strip) == expected_fs

                @test multiline(str, "fk") == expected_fk
                @test multiline(str, "fc") == expected_fc
                @test multiline(str, "fs") == expected_fs

                @test multiline(str, ">+") == expected_fk
                @test multiline(str, ">-") == expected_fs
            end

            @testset "default chomp" begin
                @test multiline(str, style=:literal) == expected_ls
                @test multiline(str, style=:folded) == expected_fs

                @test multiline(str, "l") == expected_ls
                @test multiline(str, "f") == expected_fs

                @test multiline(str, "|") == expected_lc
                @test multiline(str, ">") == expected_fc
            end

            @testset "default style" begin
                @test multiline(str, chomp=:keep) == expected_fk
                @test multiline(str, chomp=:clip) == expected_fc
                @test multiline(str, chomp=:strip) == expected_fs

                @test multiline(str, "k") == expected_fk
                @test multiline(str, "c") == expected_fc
                @test multiline(str, "s") == expected_fs

                @test multiline(str, "+") == expected_fk
                @test multiline(str, "-") == expected_fs
            end

            @testset "default style/chomp" begin
                @test multiline(str) == expected_fs
                @test multiline(str, "") == expected_fs
            end
        end

        @testset "invalid indicators" begin
            @test_throws ArgumentError multiline("", "fs_")  # Too many indicators
            @test_throws ArgumentError multiline("", "sf")   # Order matters
            @test_throws ArgumentError multiline("", "_s")   # Invalid style
            @test_throws ArgumentError multiline("", "f_")   # Invalid chomp
            @test_throws ArgumentError multiline("", "_")    # Invalid style/chomp
        end
    end

    @testset "interpolate" begin
        @test interpolate("x") == "x"
        @test interpolate("\$x") == Expr(:string, :x)
        @test interpolate("\$(x)") == Expr(:string, :x)
        @test interpolate("\$(\"x\")") == Expr(:string, "x")

        @test interpolate("<\$x>") == Expr(:string, "<", :x, ">")
        @test interpolate("<\$(x)>") == Expr(:string, "<", :x, ">")

        # The quoting in these examples can result in exceptions being raised during parsing
        # if handled incorrectly.
        @test interpolate("\"\\n\"") == "\"\\n\""
        @test interpolate("\$(join([\"a\", \"b\"], \", \"))") == Expr(:string, :(join(["a", "b"], ", ")))
    end

    @testset "@m_str" begin
        @testset "quoting" begin
            # Use of double-quotes could cause failure if not handled properly:
            # `syntax: incomplete: invalid string syntax`
            @test m"\"\n\"" == "\" \""
        end

        @testset "string-interpolation" begin
            # If processing would accidentally take place in the interpolated code then
            # we could see "a b " as the result.
            @test m"""$(join(("a", "b") .* "\n", ""))"""fc == "a b\n"
        end
    end

    include("indent.jl")

    doctest(MultilineStrings)
end
