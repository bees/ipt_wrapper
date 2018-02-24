defmodule IPTWrapper do
  @moduledoc """
  Convenience wrapper for CRF++ models trained by NYTimes' ingredient-phrase-tagger
  """

  def export_data(ingredients) do
    ingredients
    |> Enum.map(fn line ->
      Regex.replace(~r{<[^<]+?>}, line, "")
      |> clump_fractions
      |> tokenize
      |> append_features
    end)
    |> Enum.join("\n")
    |> IO.inspect()
  end

  @doc """
  Replaces the whitespace between the integer and fractional part of a quantity
  with a dollar sign, so it's interpreted as a single token. The rest of the
  string is left alone.
  """
  def clump_fractions(ingredient_string) do
    Regex.replace(~r{(\d+)\s+(\d)/(\d)}, ingredient_string, "\\1$\\2/\\3")
  end

  @doc """
  Split a given line into tokens CRF++ can parse
  """
  def tokenize(ingredient_string) do
    Regex.split(~r{([\,\(\)\s])+?}, ingredient_string, include_captures: true, trim: true)
    |> Enum.filter(fn token -> token != " " end)
  end

  def append_features(tokens) do
    tokens
    |> Enum.with_index(1)
    |> Enum.map(fn {token, index} -> build_features(token, index, tokens) end)
  end

  def build_features(token, index, tokens) do
    "#{token}\tI#{index}\tL#{bucket(tokens)}\t#{is_capitalized(token)}CAP\t#{
      inside_parens(token, tokens)
    }PAREN\n"
  end

  def bucket(tokens) when length(tokens) < 4, do: "4"
  def bucket(tokens) when length(tokens) < 8, do: "8"
  def bucket(tokens) when length(tokens) < 12, do: "12"
  def bucket(tokens) when length(tokens) < 16, do: "16"
  def bucket(tokens) when length(tokens) < 20, do: "20"
  def bucket(tokens), do: "X"

  def is_capitalized(token) do
    case String.at(token, 0) =~ ~r/^\p{Lu}$/u do
      true -> "Yes"
      false -> "No"
    end
  end

  def inside_parens(token, _) when token in ["(", ")"], do: "Yes"

  def inside_parens(token, tokens) do
    # this match is bugged but so is the one that the NYT one uses to train the models so the behavior is kept consistent
    case Regex.match?(~r{.*\(.*#{token}.*\).*}, Enum.join(tokens, " ")) do
      true -> "Yes"
      false -> "No"
    end
  end
end
