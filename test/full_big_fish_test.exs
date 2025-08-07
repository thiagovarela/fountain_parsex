defmodule FullBigFishTest do
  use ExUnit.Case

  test "parses full Big Fish script with correct token structure" do
    # Load the full script
    script_path = Path.join(__DIR__, "../samples/Big-Fish.fountain")
    script = File.read!(script_path)

    result = FountainParsex.parse(script)

    # Test title page metadata
    assert result.title == "Big Fish"

    # Test that we have a reasonable number of tokens for this full script
    assert length(result.tokens) > 100

    # Test title page tokens (first several tokens)
    # Title token
    assert Enum.at(result.tokens, 0).type == :title
    assert Enum.at(result.tokens, 0).text == "Big Fish"

    # Credit token
    assert Enum.at(result.tokens, 1).type == :credit
    assert Enum.at(result.tokens, 1).text == "written by"

    # Author token
    assert Enum.at(result.tokens, 2).type == :author
    assert Enum.at(result.tokens, 2).text == "John August"

    # Source token
    assert Enum.at(result.tokens, 3).type == :source
    assert Enum.at(result.tokens, 3).text == "based on the novel by Daniel Wallace"

    # Notes token
    assert Enum.at(result.tokens, 4).type == :notes

    assert Enum.at(result.tokens, 4).text ==
             "\nFINAL PRODUCTION DRAFT\nincludes post-production dialogue\nand omitted scenes"

    # Copyright token
    assert Enum.at(result.tokens, 5).type == :copyright
    assert Enum.at(result.tokens, 5).text == "(c) 2003 Columbia Pictures"

    # First scene heading
    first_scene_index = 21
    assert Enum.at(result.tokens, first_scene_index).type == :scene_heading
    assert Enum.at(result.tokens, first_scene_index).text == "INT.  WILL'S BEDROOM - NIGHT (1973)"

    # Action after first scene heading
    assert Enum.at(result.tokens, first_scene_index + 1).type == :action

    assert String.contains?(
             Enum.at(result.tokens, first_scene_index + 1).text,
             "WILL BLOOM, AGE 3"
           )

    # Find and validate first dialogue block with voice over
    first_dialogue_begin = find_first_dialogue_begin(result.tokens, first_scene_index + 2)
    assert first_dialogue_begin != nil

    # Check basic dialogue structure
    assert Enum.at(result.tokens, first_dialogue_begin).type == :dialogue_begin
    assert Enum.at(result.tokens, first_dialogue_begin + 1).type == :character
    assert Enum.at(result.tokens, first_dialogue_begin + 1).text == "EDWARD"
    assert Enum.at(result.tokens, first_dialogue_begin + 2).type == :dialogue

    assert String.contains?(
             Enum.at(result.tokens, first_dialogue_begin + 2).text,
             "I didn't put any stock"
           )

    # Find and validate second scene heading
    second_scene_index = find_next_scene_heading(result.tokens, first_scene_index + 1)
    assert second_scene_index != nil
    assert Enum.at(result.tokens, second_scene_index).type == :scene_heading

    assert Enum.at(result.tokens, second_scene_index).text ==
             "EXT.  CAMPFIRE - NIGHT (1977)"

    # Find and validate dialogue block with parenthetical
    parenthetical_dialogue_begin =
      find_dialogue_with_parenthetical(result.tokens, second_scene_index + 1)

    assert parenthetical_dialogue_begin != nil

    validate_dialogue_block_with_parenthetical(
      result.tokens,
      parenthetical_dialogue_begin,
      "LITTLE BRAVE",
      "(confused)",
      "Your finger?"
    )

    # Test that we have multiple scene headings
    scene_headings = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
    assert length(scene_headings) > 10

    # Test that we have multiple dialogue blocks
    dialogue_begins = Enum.filter(result.tokens, fn token -> token.type == :dialogue_begin end)
    assert length(dialogue_begins) > 20

    # Test that we have character names
    characters = Enum.filter(result.tokens, fn token -> token.type == :character end)
    character_names = Enum.map(characters, fn token -> token.text end) |> Enum.uniq()

    # Verify expected characters are present
    assert "EDWARD" in character_names
    assert "EDWARD (V.O.)" in character_names
    assert "WILL" in character_names
    assert "SANDRA" in character_names
    assert "JOSEPHINE" in character_names
    assert "LITTLE BRAVE" in character_names
    assert "WILL'S DATE" in character_names

    # Test that we have action lines
    actions = Enum.filter(result.tokens, fn token -> token.type == :action end)
    assert length(actions) >= 50

    # Test that we have parentheticals
    parentheticals = Enum.filter(result.tokens, fn token -> token.type == :parenthetical end)
    assert length(parentheticals) > 5

    # Test scene headings - verify we have the expected ones
    scene_headings = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
    scene_heading_texts = Enum.map(scene_headings, fn token -> token.text end)

    # Verify expected scene headings are present (note: "A RIVER." is parsed as action, not scene heading)
    assert "INT.  WILL'S BEDROOM - NIGHT (1973)" in scene_heading_texts
    assert "EXT.  CAMPFIRE - NIGHT (1977)" in scene_heading_texts
    assert "INT.  BLOOM FRONT HALL - NIGHT (1987)" in scene_heading_texts
    assert "INT.  TINY PARIS RESTAURANT (LA RUE 14°) - NIGHT (1998)" in scene_heading_texts
    assert "EXT.  OUTSIDE LA RUE 14° - NIGHT" in scene_heading_texts
    assert "INT.  A.P. NEWSROOM (PARIS) - DAY" in scene_heading_texts

    # Test for centered text (FADE IN)
    centered_texts = Enum.filter(result.tokens, fn token -> token.type == :centered end)
    assert length(centered_texts) > 0

    # Verify specific centered text content
    the_end_centered = Enum.find(centered_texts, fn token -> token.text == "_**THE END**_" end)
    assert the_end_centered != nil

    # Test for transitions
    transitions = Enum.filter(result.tokens, fn token -> token.type == :transition end)
    assert length(transitions) >= 1

    # Test for notes
    notes = Enum.filter(result.tokens, fn token -> token.type == :notes end)
    assert length(notes) >= 1

    # Test for copyright
    copyrights = Enum.filter(result.tokens, fn token -> token.type == :copyright end)
    assert length(copyrights) >= 1

    # Test for voice over dialogue
    voice_over_characters =
      Enum.filter(character_names, fn name -> String.contains?(name, "(V.O.)") end)

    assert length(voice_over_characters) > 0

    # Test for continued dialogue (CONT'D)
    continued_dialogues =
      Enum.filter(character_names, fn name -> String.contains?(name, "(CONT'D)") end)

    assert length(continued_dialogues) > 0
  end

  # Helper functions to find and validate token patterns

  defp find_first_dialogue_begin(tokens, start_index) do
    tokens
    |> Enum.drop(start_index)
    |> Enum.find_index(fn token -> token.type == :dialogue_begin end)
    |> case do
      nil -> nil
      index -> start_index + index
    end
  end

  defp find_next_scene_heading(tokens, start_index) do
    tokens
    |> Enum.drop(start_index)
    |> Enum.find_index(fn token -> token.type == :scene_heading end)
    |> case do
      nil -> nil
      index -> start_index + index
    end
  end

  defp find_dialogue_with_parenthetical(tokens, start_index) do
    tokens
    |> Enum.drop(start_index)
    |> Enum.chunk_every(5, 1, :discard)
    |> Enum.find_index(fn chunk ->
      length(chunk) >= 5 and
        Enum.at(chunk, 0).type == :dialogue_begin and
        Enum.at(chunk, 2).type == :parenthetical
    end)
    |> case do
      nil -> nil
      index -> start_index + index
    end
  end

  defp validate_dialogue_block_with_parenthetical(
         tokens,
         start_index,
         expected_character,
         expected_parenthetical,
         expected_dialogue
       ) do
    assert Enum.at(tokens, start_index).type == :dialogue_begin
    assert Enum.at(tokens, start_index + 1).type == :character
    assert Enum.at(tokens, start_index + 1).text == expected_character
    assert Enum.at(tokens, start_index + 2).type == :parenthetical
    assert Enum.at(tokens, start_index + 2).text == expected_parenthetical
    assert Enum.at(tokens, start_index + 3).type == :dialogue
    assert String.contains?(Enum.at(tokens, start_index + 3).text, expected_dialogue)
    assert Enum.at(tokens, start_index + 4).type == :dialogue_end
  end
end
