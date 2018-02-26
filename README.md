# IPTWrapper

A simplistic wrapper for interacting with
[CRF++](https://taku910.github.io/crfpp/) using models trained by NYT's
[ingredient-phrase-tagger](https://github.com/NYTimes/ingredient-phrase-tagger/).

Note: this wrapper merely calls `crf_test` which is an external dependency for
this project. I haven't looked into writing ports/nifs  - I don't plan to
unless it becomes necessary.

I am unlikely to publish this to hex as it is incredibly limited in scope and
ugly in implementation. Feel free to leave an issue if you'd like to see that
changed.

## Why?

Interacting with CRF++ is a prerequisite for a larger project I have planned.
This was done to simplify deployment (gets rid of Python as a dependency). This
library will be used for batch processing of large collections of text so being
able to minimize overhead (Elixir -> Python -> CRF++ vs Elixir -> CRF++) is an
added bonus.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ipt_wrapper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ipt_wrapper, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ipt_wrapper](https://hexdocs.pm/ipt_wrapper).

