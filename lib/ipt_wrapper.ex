defmodule IPTWrapper do
  @model_path Application.get_env(:ipt_wrapper, :model_path, "priv/model")
  @moduledoc """
  Convenience wrapper for CRF++ models trained by NYTimes' ingredient-phrase-tagger
  """
  alias Porcelain.Result

  def test_crf(ingredients, file_id \\ "") do
    {:ok, file_path} = Temp.open("recipe#{file_id}", &IO.write(&1, export_data(ingredients)))

    result = Porcelain.exec("crf_test", ["-v", "1", "-m", "#{@model_path}", "#{file_path}"])
    File.rm(file_path)

    case result do
      %Result{status: 0, out: output} ->
        {:ok, import_data(output)}

      %Result{status: status, err: err} ->
        {:error, "crf_test return with status #{status} #{err}"}
    end
  end

  @doc """
  Parse crfpp formatted output into a list of Elixir maps containing ingredient information
  """
  def import_data(crfpp_data) do
    crfpp_data
    |> String.split("\n\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(fn crfpp_chunk ->
      String.split(crfpp_chunk, "\n")
      |> Enum.filter(fn line -> String.at(line, 0) != "#" end)
      |> Enum.map(fn line ->
        String.split(line, "\t")
        |> parse_crfpp_ingredient_tokens
      end)
      |> Enum.filter(fn {tag, data} -> tag != "other" and data not in [",", "."] end)
      |> Enum.map(fn
        {"qty", data} -> {"qty", Regex.replace(~r{\$}, data, " ")}
        {"unit", data} -> {"unit", singularize_unit(data)}
        qty_tuple -> qty_tuple
      end)
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.merge(acc, %{key => value}, fn _k, v1, v2 -> v1 <> " " <> v2 end)
      end)
    end)
  end

  @doc """
  Parse a list of crfpp tokens into an Elixir map containing ingredient information
  """
  def parse_crfpp_ingredient_tokens(tokens = [data | _tail]) do
    [raw_tag | _confidence] = Enum.at(tokens, -1) |> String.split("/")
    tag = Regex.replace(~r{^[BI]\-}, raw_tag, "") |> String.downcase()

    {tag, data}
  end

  @doc """
  Given a list of ingredients, return a stream that can be consumed by crfpp's crf_test
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
  def bucket(_tokens), do: "X"

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

  def singularize_unit(data) do
    case String.downcase(data) do
      "cups" -> "cup"
      "tablespoons" -> "tablespoon"
      "teaspoons" -> "teaspoon"
      "pounds" -> "pound"
      "ounces" -> "ounce"
      "cloves" -> "clove"
      "sprigs" -> "sprig"
      "pinches" -> "pinch"
      "bunches" -> "bunch"
      "slices" -> "slice"
      "grams" -> "gram"
      "heads" -> "head"
      "quarts" -> "quart"
      "stalks" -> "stalk"
      "pints" -> "pint"
      "pieces" -> "piece"
      "sticks" -> "stick"
      "dashes" -> "dash"
      "fillets" -> "fillet"
      "cans" -> "can"
      "ears" -> "ear"
      "packages" -> "package"
      "strips" -> "strip"
      "bulbs" -> "bulb"
      "bottles" -> "bottle"
      _ -> data
    end
  end
end
