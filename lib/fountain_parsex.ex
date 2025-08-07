defmodule FountainParsex do
  @moduledoc """
  A Fountain screenplay parser for Elixir.

  Fountain is a plain text markup language for screenwriting.
  This library parses Fountain format scripts into structured tokens.
  """

  alias FountainParsex.Lexer
  alias FountainParsex.Tokenizer
  alias FountainParsex.Types.{ParseResult, Scene}

  @doc """
  Parses a Fountain script and returns structured data.

  ## Examples

  Basic usage:

      result = FountainParsex.parse("EXT. HOUSE - DAY\\n\\nJOHN\\nHello, world!")
      # Returns a ParseResult struct with parsed tokens
  """
  def parse(script, opts \\ []) do
    # Reject any options to maintain backward compatibility error handling
    if opts != [] do
      raise ArgumentError,
            "FountainParsex.parse/2 no longer accepts options. Tokens are always included."
    end

    script
    |> Lexer.preprocess()
    |> Tokenizer.tokenize()
    |> generate_result()
  end

  defp generate_result(tokens) do
    # Extract title from title page tokens
    title =
      Enum.find_value(tokens, fn token ->
        if token.type == :title, do: token.text, else: nil
      end)

    %ParseResult{
      title: title,
      tokens: tokens
    }
  end

  @doc """
  Groups tokens into scenes based on scene headings.

  ## Examples

      result = FountainParsex.parse("EXT. HOUSE - DAY\\n\\nJOHN\\nHello, world!")
      scenes = FountainParsex.scenes(result.tokens)
      # Returns list of Scene structs with heading and content tokens
  """
  def scenes(tokens) do
    tokens
    |> group_scenes()
  end

  defp group_scenes(tokens) do
    {scenes, current_scene} =
      Enum.reduce(tokens, {[], nil}, fn token, {scenes, current_scene} ->
        process_token_for_scene(token, scenes, current_scene)
      end)

    # Add the last scene if it exists and reverse to maintain original order
    final_scenes =
      if current_scene do
        [current_scene | scenes]
      else
        scenes
      end

    Enum.reverse(final_scenes)
  end

  defp process_token_for_scene(token, scenes, current_scene) do
    case token.type do
      :scene_heading ->
        handle_scene_heading(token, scenes, current_scene)

      _ ->
        handle_non_scene_token(token, scenes, current_scene)
    end
  end

  defp handle_scene_heading(token, scenes, current_scene) do
    # If we have a current scene, add it to scenes list
    new_scenes =
      if current_scene do
        [current_scene | scenes]
      else
        scenes
      end

    # Start new scene with this heading
    new_scene = %Scene{
      heading: token,
      content: []
    }

    {new_scenes, new_scene}
  end

  defp handle_non_scene_token(token, scenes, current_scene) do
    # Skip title page tokens (they come before first scene)
    if title_page_token?(token.type) and current_scene == nil do
      {scenes, current_scene}
    else
      add_token_to_scene(token, scenes, current_scene)
    end
  end

  defp add_token_to_scene(token, scenes, current_scene) do
    if current_scene do
      updated_scene = %{current_scene | content: current_scene.content ++ [token]}
      {scenes, updated_scene}
    else
      # Tokens before first scene heading (like action) - create scene without heading
      new_scene = %Scene{
        heading: nil,
        content: [token]
      }

      {scenes, new_scene}
    end
  end

  defp title_page_token?(token_type) do
    token_type in [:title, :credit, :author, :source, :notes, :copyright, :contact, :draft_date]
  end
end
