defmodule FountainParsex.Regex do
  @moduledoc """
  Regex patterns for Fountain parsing based on the official Fountain syntax.
  """

  @doc """
  Returns regex for scene headings including forced headings with period.
  Matches: INT. HOUSE - DAY, .FORCED SCENE
  """
  def scene_heading do
    ~r/^((?:\*{0,3}_?)?(?:(?:int|ext|est|i\/e)[. ]).+)|^(?:\.(?!\.+))(.+)/i
  end

  @doc """
  Returns regex for scene numbers wrapped in # symbols.
  Matches: #1#, #1A#, #I-1-A#
  """
  def scene_number do
    ~r/( *#(.+)# *)/
  end

  @doc """
  Returns regex for character names and dialogue blocks.
  Matches: CHARACTER\nDialogue text
  """
  def character_dialogue do
    ~r/^([A-Z*_]+[0-9A-Z (._\-')]*)(\^?)?(?:\n(?!\n+))([\s\S]+)/
  end

  @doc """
  Returns regex for parentheticals.
  Matches: (whispering)
  """
  def parenthetical do
    ~r/^(\(.+\))$/
  end

  @doc """
  Returns regex for transitions.
  Matches: CUT TO:, >SMASH CUT
  """
  def transition do
    ~r/^((?:FADE (?:TO BLACK|OUT)|CUT TO BLACK)\.|.+ TO:)|^(?:> *)(.+)/
  end

  @doc """
  Returns regex for title page key-value pairs.
  Matches: Title: My Script
  """
  def title_page do
    ~r/^((?:title|credit|author[s]?|source|notes|draft date|date|contact|copyright):)/i
  end

  @doc """
  Returns regex for sections (outline structure).
  Matches: # Act 1, ## Sequence A
  """
  def section do
    ~r/^(#+)(?: *)(.*)/
  end

  @doc """
  Returns regex for synopses.
  Matches: = This describes the scene
  """
  def synopsis do
    ~r/^(?:=(?!=+) *)(.*)/
  end

  @doc """
  Returns regex for notes.
  Matches: [[This is a note]]
  """
  def note do
    ~r/^(?:\[{2}(?!\[+))(.+)(?:\]{2}(?!\[+))$/
  end

  @doc """
  Returns regex for inline notes.
  Matches: [[inline note]] within text
  """
  def note_inline do
    ~r/(?:\[{2}(?!\[+))([\s\S]+?)(?:\]{2}(?!\[+))/
  end

  @doc """
  Returns regex for boneyard (ignored text).
  Matches: /* ignored text */
  """
  def boneyard do
    ~r/(^\/\*|^\*\/)$/
  end

  @doc """
  Returns regex for page breaks.
  Matches: ===
  """
  def page_break do
    ~r/^={3,}$/
  end

  @doc """
  Returns regex for line breaks (two spaces).
  Matches: '  '
  """
  def line_break do
    ~r/^ {2}$/
  end

  @doc """
  Returns regex for centered text.
  Matches: >CENTERED TEXT<
  """
  def centered do
    ~r/^(?:> *)(.+)(?: *<)(\n.+)*/
  end

  @doc """
  Returns regex for lyrics.
  Matches: ~Willy Wonka lyrics
  """
  def lyrics do
    ~r/^~(.*)/
  end

  @doc """
  Returns map of emphasis patterns.
  """
  def emphasis do
    %{
      bold_italic_underline:
        ~r/(_{1}\*{3}(?=.+\*{3}_{1})|\*{3}_{1}(?=.+_{1}\*{3}))(.+?)(\*{3}_{1}|_{1}\*{3})/,
      bold_underline:
        ~r/(_{1}\*{2}(?=.+\*{2}_{1})|\*{2}_{1}(?=.+_{1}\*{2}))(.+?)(\*{2}_{1}|_{1}\*{2})/,
      italic_underline:
        ~r/(?:_{1}\*{1}(?=.+\*{1}_{1})|\*{1}_{1}(?=.+_{1}\*{1}))(.+?)(\*{1}_{1}|_{1}\*{1})/,
      bold_italic: ~r/(\*{3}(?=.+\*{3}))(.+?)(\*{3})/,
      bold: ~r/(\*{2}(?=.+\*{2}))(.+?)(\*{2})/,
      italic: ~r/(\*{1}(?=.+\*{1}))(.+?)(\*{1})/,
      underline: ~r/(_{1}(?=.+_{1}))(.+?)(_{1})/
    }
  end

  @doc """
  Returns splitting patterns for text processing.
  """
  def splitting do
    %{
      block_separator: ~r/\n{2,}/,
      cleaner: ~r/^\n+|\n+$/,
      standardizer: ~r/\r\n|\r/,
      whitespacer: ~r/^\t+|^ {3,}/m
    }
  end
end
