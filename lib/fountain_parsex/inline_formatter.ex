defmodule FountainParsex.InlineFormatter do
  @moduledoc """
  Handles inline formatting for emphasis, notes, and other text decorations.
  """

  @doc """
  Applies inline formatting to text including emphasis, notes, and line breaks.
  """
  def format(text) do
    text
    |> process_notes()
    |> process_line_breaks()
    |> process_emphasis()
    |> process_escapes()
    |> String.trim()
  end

  @doc """
  Processes inline notes [[note]] into HTML comments.
  """
  def process_notes(text) do
    text
    |> String.replace(~r/\[\[([^\]]+)\]\]/, "<!-- \\1 -->")
  end

  @doc """
  Processes line breaks (double spaces at line end) into <br /> tags.
  """
  def process_line_breaks(text) do
    text
    |> String.replace("  \n", "<br />\n")
    |> String.replace("\n", "<br />\n")
  end

  @doc """
  Processes emphasis formatting (*bold*, **italic**, _underline_, etc.).
  """
  def process_emphasis(text) do
    text
    # Handle bold italic underline
    |> String.replace(
      ~r/(_{1}\*{3}(?=.+\*{3}_{1})|\*{3}_{1}(?=.+_{1}\*{3}))(.+?)(\*{3}_{1}|_{1}\*{3})/,
      "<span class=\"bold italic underline\">\\2</span>"
    )
    # Handle bold underline
    |> String.replace(
      ~r/(_{1}\*{2}(?=.+\*{2}_{1})|\*{2}_{1}(?=.+_{1}\*{2}))(.+?)(\*{2}_{1}|_{1}\*{2})/,
      "<span class=\"bold underline\">\\2</span>"
    )
    # Handle italic underline
    |> String.replace(
      ~r/(?:_{1}\*{1}(?=.+\*{1}_{1})|\*{1}_{1}(?=.+_{1}\*{1}))(.+?)(\*{1}_{1}|_{1}\*{1})/,
      "<span class=\"italic underline\">\\2</span>"
    )
    # Handle bold italic
    |> String.replace(
      ~r/(\*{3}(?=.+\*{3}))(.+?)(\*{3})/,
      "<span class=\"bold italic\">\\2</span>"
    )
    # Handle bold
    |> String.replace(~r/(\*{2}(?=.+\*{2}))(.+?)(\*{2})/, "<span class=\"bold\">\\2</span>")
    # Handle italic
    |> String.replace(~r/(\*{1}(?=.+\*{1}))(.+?)(\*{1})/, "<span class=\"italic\">\\2</span>")
    # Handle underline
    |> String.replace(~r/(_{1}(?=.+_{1}))(.+?)(_{1})/, "<span class=\"underline\">\\2</span>")
  end

  @doc """
  Processes escaped characters (backslash escapes).
  """
  def process_escapes(text) do
    text
    |> String.replace("\\*", "[star]")
    |> String.replace("\\_", "[underline]")
    |> String.replace("[star]", "*")
    |> String.replace("[underline]", "_")
  end
end
