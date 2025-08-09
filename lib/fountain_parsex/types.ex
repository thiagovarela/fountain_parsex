defmodule FountainParsex.Types do
  @moduledoc """
  Type definitions for Fountain parsing.
  """

  defmodule Token do
    @moduledoc """
    Represents a parsed fountain element token.
    """
    @type t :: %__MODULE__{
            type: atom(),
            text: String.t() | nil,
            scene_number: String.t() | nil,
            depth: integer() | nil,
            dual: boolean() | nil,
            line_number: integer() | nil
          }
    defstruct [:type, :text, :scene_number, :depth, :dual, :line_number]
  end

  defmodule ParseResult do
    @moduledoc """
    The result of parsing a fountain script.
    """
    @type t :: %__MODULE__{
            title: String.t() | nil,
            tokens: [Token.t()]
          }
    defstruct [:title, :tokens]
  end

  defmodule TitlePageItem do
    @moduledoc """
    Represents a title page key-value pair.
    """
    @type t :: %__MODULE__{
            key: String.t(),
            value: String.t()
          }
    defstruct [:key, :value]
  end

  defmodule Scene do
    @moduledoc """
    Represents a scene with its heading and content text.
    """
    @type t :: %__MODULE__{
            heading: Token.t() | nil,
            content: String.t()
          }
    defstruct [:heading, :content]
  end
end
