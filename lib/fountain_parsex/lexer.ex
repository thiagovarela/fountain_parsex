defmodule FountainParsex.Lexer do
  @moduledoc """
  Text preprocessing for Fountain parsing.
  Handles cleaning, normalizing, and preparing text for tokenization.
  """

  # alias FountainParsex.Regex, as: FRegex

  @doc """
  Preprocesses the fountain script text for parsing.
  Handles boneyard removal, line ending normalization, and basic cleaning.
  """
  def preprocess(text) do
    text
    |> remove_boneyard()
    |> normalize_line_endings()
    |> clean_whitespace()
    |> handle_whitespace_indentation()
  end

  @doc """
  Removes boneyard sections (/* ... */) from the text.
  """
  def remove_boneyard(text) do
    # Remove boneyard sections completely
    Regex.replace(~r/\/\*[\s\S]*?\*\//, text, "")
  end

  @doc """
  Normalizes line endings to Unix format (\n).
  """
  def normalize_line_endings(text) do
    text
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
  end

  @doc """
  Cleans leading and trailing whitespace from the text.
  """
  def clean_whitespace(text) do
    text
    |> String.trim()
    |> String.replace(~r/\n{3,}/, "\n\n")
  end

  @doc """
  Handles whitespace indentation - removes leading tabs and 3+ spaces
  except for Action elements where they're preserved.
  """
  def handle_whitespace_indentation(text) do
    # We'll handle this more carefully during tokenization
    # For now, just normalize tabs to spaces
    String.replace(text, "\t", "    ")
  end

  @doc """
  Splits text into logical blocks separated by double newlines.
  """
  def split_blocks(text) do
    text
    |> String.split(~r/\n{2,}/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Splits text into lines while preserving empty lines.
  """
  def split_lines(text) do
    String.split(text, "\n")
  end
end
