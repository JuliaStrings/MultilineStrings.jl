# MultilineStrings

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/MultilineStrings.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/MultilineStrings.jl/dev)
[![Build Status](https://travis-ci.com/invenia/MultilineStrings.jl.svg?branch=master)](https://travis-ci.com/invenia/MultilineStrings.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Tooling for manipulating multiline strings.

## Features

The package features a multiline string literal (`@m_str`), inspired from [YAML's block scalars](https://yaml-multiline.info/), which provide options for manipulating multiline string literals via a style and chomp indicator:

- Style indicator:
    - `f` replace newlines with spaces (folded)
    - `l` keep newlines (literal)
- Chomp indicator:
    - `s` no newlines at the end (strip)
    - `c` single newline at the end (clip)
    - `k` keep all newlines from the end (keep)

The indicators are provided after the ending quote of the string (e.g. `m"hello\nworld!"fc`).
If no indicators are provided the default behaviour is folded/strip.

## Example

When writing a long string literal you may want to break the string up over multiple lines in the code, to make it easier to read, but have the string be printed as a single line.
Specifically, when writing an long error message you may want to break up the string over multiple lines:

```julia
"An unexpected error has occurred which really shouldn't have happened but somehow did. Please check that the inputs to this function doesn't contain magic that may interfere with with the non-magical computation occurring on this device."
```

Alternatively written over multiple lines:

```julia
"An unexpected error has occurred which really shouldn't " *
"have happened but somehow did. Please check that the inputs " *
"to this function doesn't contain magic that may interfere with " *
"with the non-magical computation occurring on this device."
```

Writing strings this way can be cumbersome as you need to remember to add spaces between each line.
The MultilineStrings package provides an alternative way of writing this using the multiline string macro:

```julia
m"""
An unexpected error has occurred which really shouldn't
have happened but somehow did. Please check that the inputs
to this function doesn't contain magic that may interfere with
with the non-magical computation occurring on this device.
"""
```

Take note that a Julia [triple-quoted string literal](https://docs.julialang.org/en/v1/manual/strings/#Triple-Quoted-String-Literals) will leave most newlines in place.