@testset "indent" begin
    @test indent("", 4) == ""
    @test indent("\n", 4) == "\n"
    @test indent("  \n  ", 2) == "  \n  "

    @test indent("a", 4) == "    a"
    @test indent("a\n\nb", 4) == "    a\n\n    b"

    @test indent("三\nb", 4) == "    三\n    b"
end
