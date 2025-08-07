defmodule FountainParsex.Tokenizer do
  @moduledoc """
  Tokenizes Fountain script blocks into structured tokens.
  """

  alias FountainParsex.Regex, as: FRegex
  alias FountainParsex.Types.Token

  @doc """
  Tokenizes a preprocessed fountain script into tokens.
  """
  def tokenize(script) do
    blocks = FountainParsex.Lexer.split_blocks(script)

    {tokens, _state} =
      blocks
      |> Enum.with_index(1)
      |> Enum.reduce({[], %{in_dialogue: false, dual: false}}, &process_block/2)

    tokens
  end

  defp process_block({block, line_number}, {tokens, state}) do
    process_classified_block(classify_block(block), block, line_number, {tokens, state})
  end

  defp process_classified_block(classification, block, line_number, acc) do
    apply_classification(classification, block, line_number, acc)
  end

  defp apply_classification(:title_page, block, line_number, acc),
    do: process_title_page(block, line_number, acc)

  defp apply_classification(:scene_heading, block, line_number, acc),
    do: process_scene_heading(block, line_number, acc)

  defp apply_classification(:centered, block, line_number, acc),
    do: process_centered(block, line_number, acc)

  defp apply_classification(:transition, block, line_number, acc),
    do: process_transition(block, line_number, acc)

  defp apply_classification(:character_dialogue, block, line_number, acc),
    do: process_character_dialogue(block, line_number, acc)

  defp apply_classification(:section, block, line_number, acc),
    do: process_section(block, line_number, acc)

  defp apply_classification(:synopsis, block, line_number, acc),
    do: process_synopsis(block, line_number, acc)

  defp apply_classification(:lyrics, block, line_number, acc),
    do: process_lyrics(block, line_number, acc)

  defp apply_classification(:page_break, block, line_number, acc),
    do: process_page_break(block, line_number, acc)

  defp apply_classification(:action, block, line_number, acc),
    do: process_action(block, line_number, acc)

  defp classify_block(block) do
    cond do
      structural_element?(block) -> classify_structural_element(block)
      dialogue_element?(block) -> classify_dialogue_element(block)
      formatting_element?(block) -> classify_formatting_element(block)
      true -> :action
    end
  end

  defp structural_element?(block),
    do: title_page?(block) or scene_heading?(block) or section?(block)

  defp dialogue_element?(block), do: character_dialogue?(block)

  defp formatting_element?(block),
    do:
      centered?(block) or transition?(block) or synopsis?(block) or lyrics?(block) or
        page_break?(block)

  defp classify_structural_element(block) do
    cond do
      title_page?(block) -> :title_page
      scene_heading?(block) -> :scene_heading
      section?(block) -> :section
    end
  end

  defp classify_dialogue_element(_block), do: :character_dialogue

  defp classify_formatting_element(block) do
    cond do
      centered?(block) -> :centered
      transition?(block) -> :transition
      synopsis?(block) -> :synopsis
      lyrics?(block) -> :lyrics
      page_break?(block) -> :page_break
    end
  end

  defp title_page?(block) do
    String.match?(block, FRegex.title_page())
  end

  defp scene_heading?(block) do
    String.match?(block, FRegex.scene_heading())
  end

  defp transition?(block) do
    String.match?(block, FRegex.transition())
  end

  defp character_dialogue?(block) do
    String.match?(block, FRegex.character_dialogue())
  end

  defp section?(block) do
    String.match?(block, FRegex.section())
  end

  defp synopsis?(block) do
    String.match?(block, ~r/^=(?!={2,})(?: *)(.*)/)
  end

  defp centered?(block) do
    String.match?(block, ~r/^>\s*(.+?)\s*<$/)
  end

  defp lyrics?(block) do
    String.match?(block, FRegex.lyrics())
  end

  defp page_break?(block) do
    String.trim(block) == "==="
  end

  defp process_title_page(block, line_number, {tokens, state}) do
    if title_page_block?(block) do
      title_tokens = extract_title_page_tokens(block, line_number)
      {tokens ++ title_tokens, state}
    else
      process_action(block, line_number, {tokens, state})
    end
  end

  defp title_page_block?(block) do
    lines = String.split(block, "\n")
    first_line = String.trim(Enum.at(lines, 0) || "")

    String.match?(
      first_line,
      ~r/^(title|credit|author[s]?|source|notes|draft date|date|contact|copyright):/i
    )
  end

  defp extract_title_page_tokens(block, line_number) do
    lines = String.split(block, "\n")

    {title_tokens, _} =
      Enum.reduce(lines, {[], nil}, &process_title_page_line(&1, &2, line_number))

    Enum.reverse(title_tokens)
  end

  defp process_title_page_line(line, {acc, current_key}, line_number) do
    line = String.trim(line)

    cond do
      line == "" -> {acc, current_key}
      title_page_key_line?(line) -> process_title_page_key_line(line, acc, line_number)
      current_key != nil -> process_title_page_continuation(line, acc, current_key)
      true -> {acc, current_key}
    end
  end

  defp title_page_key_line?(line) do
    String.match?(
      line,
      ~r/^(title|credit|author[s]?|source|notes|draft date|date|contact|copyright):/i
    )
  end

  defp process_title_page_key_line(line, acc, line_number) do
    [key, value] = String.split(line, ":", parts: 2)
    key = String.downcase(key) |> String.trim() |> String.replace(" ", "_")
    value = String.trim(value)

    token = %Token{
      type: String.to_atom(key),
      text: value,
      line_number: line_number
    }

    {[token | acc], key}
  end

  defp process_title_page_continuation(line, acc, current_key) do
    [last_token | rest] = acc
    continuation = String.trim(line)

    updated_token = %Token{
      last_token
      | text: last_token.text <> "\n" <> continuation
    }

    {[updated_token | rest], current_key}
  end

  defp process_scene_heading(block, line_number, {tokens, state}) do
    text = String.trim(block)

    # Remove leading dot for forced scene headings
    text = String.replace(text, ~r/^\.(\s*)(.+)/, "\\2")

    {text, scene_number} =
      case Regex.run(FRegex.scene_number(), text) do
        [_, _, num] -> {String.replace(text, FRegex.scene_number(), ""), num}
        _ -> {text, nil}
      end

    token = %Token{
      type: :scene_heading,
      text: String.trim(text),
      scene_number: scene_number,
      line_number: line_number
    }

    {tokens ++ [token], state}
  end

  defp process_transition(block, line_number, {tokens, state}) do
    text = String.trim(block)
    text = String.replace(text, ~r/^>\s*/, "")
    token = %Token{type: :transition, text: text, line_number: line_number}
    {tokens ++ [token], state}
  end

  defp process_character_dialogue(block, line_number, {tokens, state}) do
    case Regex.run(FRegex.character_dialogue(), block) do
      [_, character, dual, dialogue] ->
        dual? = dual != ""

        dialogue_tokens = build_dialogue_tokens(character, dialogue, dual?, line_number)

        if dual? do
          dialogue_tokens = wrap_with_dual_dialogue(dialogue_tokens, line_number)
          # Add tokens in correct order (append to the end rather than prepend)
          {tokens ++ dialogue_tokens, state}
        else
          # Add tokens in correct order (append to the end rather than prepend)
          {tokens ++ dialogue_tokens, state}
        end

      _ ->
        process_action(block, line_number, {tokens, state})
    end
  end

  defp build_dialogue_tokens(character, dialogue, dual?, line_number) do
    parts = Regex.split(~r/(\(.+?\))(?:\n*)/, dialogue, include_captures: true, trim: true)

    dialogue_content =
      parts
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&parse_dialogue_part(&1, line_number))

    [
      %Token{type: :dialogue_begin, dual: dual?, line_number: line_number},
      %Token{type: :character, text: String.trim(character), line_number: line_number}
    ] ++ dialogue_content ++ [%Token{type: :dialogue_end, line_number: line_number}]
  end

  defp parse_dialogue_part(part, line_number) do
    if String.starts_with?(part, "(") and String.ends_with?(part, ")") do
      %Token{type: :parenthetical, text: part, line_number: line_number}
    else
      %Token{type: :dialogue, text: part, line_number: line_number}
    end
  end

  defp wrap_with_dual_dialogue(tokens, line_number) do
    [
      %Token{type: :dual_dialogue_begin, line_number: line_number}
    ] ++ tokens ++ [%Token{type: :dual_dialogue_end, line_number: line_number}]
  end

  defp process_section(block, line_number, {tokens, state}) do
    case Regex.run(FRegex.section(), block) do
      [_, hashes, text] ->
        token = %Token{
          type: :section,
          text: String.trim(text),
          depth: String.length(hashes),
          line_number: line_number
        }

        {tokens ++ [token], state}

      _ ->
        process_action(block, line_number, {tokens, state})
    end
  end

  defp process_synopsis(block, line_number, {tokens, state}) do
    text = String.trim(block)
    text = String.replace(text, ~r/^=\s*/, "")
    token = %Token{type: :synopsis, text: text, line_number: line_number}
    {tokens ++ [token], state}
  end

  defp process_centered(block, line_number, {tokens, state}) do
    text = String.trim(block)
    text = String.replace(text, ~r/^>\s*(.+?)\s*<$/, "\\1")
    token = %Token{type: :centered, text: text, line_number: line_number}
    {tokens ++ [token], state}
  end

  defp process_lyrics(block, line_number, {tokens, state}) do
    text = String.trim(block)
    text = String.replace(text, ~r/^~\s*/, "")
    token = %Token{type: :lyrics, text: text, line_number: line_number}
    {tokens ++ [token], state}
  end

  defp process_page_break(_block, line_number, {tokens, state}) do
    token = %Token{type: :page_break, line_number: line_number}
    {tokens ++ [token], state}
  end

  defp process_action(block, line_number, {tokens, state}) do
    text = String.trim(block)

    cond do
      String.trim(text) == "===" ->
        process_page_break(block, line_number, {tokens, state})

      String.match?(text, ~r/^>\s*(.+?)\s*<$/) ->
        process_centered(block, line_number, {tokens, state})

      String.match?(text, ~r/^=\s*(.+)/) ->
        process_synopsis(block, line_number, {tokens, state})

      String.match?(text, ~r/^~\s*(.+)/) ->
        process_lyrics(block, line_number, {tokens, state})

      true ->
        # Remove force indicators
        text = String.replace(text, ~r/^!\s*/, "")
        text = String.replace(text, ~r/^@\s*/, "")
        text = String.replace(text, ~r/^>\s*/, "")
        text = String.replace(text, ~r/^~\s*/, "")
        text = String.replace(text, ~r/^=\s*/, "")
        text = String.replace(text, ~r/^\.(\s*)(.+)/, "\\2")

        token = %Token{
          type: :action,
          text: text,
          line_number: line_number
        }

        {tokens ++ [token], state}
    end
  end
end
