defmodule FullBrickAndSteelTest do
  use ExUnit.Case

  test "parses full Brick & Steel script with correct token structure" do
    # Load the full script
    script_path = Path.join(__DIR__, "../samples/Brick-&-Steel.fountain")
    script = File.read!(script_path)

    result = FountainParsex.parse(script)

    # Test title page metadata
    assert result.title == "\n_**BRICK & STEEL**_\n_**FULL RETIRED**_"

    # Test that we have a reasonable number of tokens for this full script
    assert length(result.tokens) > 50

    # Test title page tokens (first several tokens)
    # Title token (combined)
    assert Enum.at(result.tokens, 0).type == :title
    assert Enum.at(result.tokens, 0).text == "\n_**BRICK & STEEL**_\n_**FULL RETIRED**_"

    # Credit token
    assert Enum.at(result.tokens, 1).type == :credit
    assert Enum.at(result.tokens, 1).text == "Written by"

    # Author token
    assert Enum.at(result.tokens, 2).type == :author
    assert Enum.at(result.tokens, 2).text == "Stu Maschwitz"

    # Source token
    assert Enum.at(result.tokens, 3).type == :source
    assert Enum.at(result.tokens, 3).text == "Story by KTM"

    # Draft date token
    assert Enum.at(result.tokens, 4).type == :draft_date
    assert Enum.at(result.tokens, 4).text == "1/27/2012"

    # Contact token (combined)
    assert Enum.at(result.tokens, 5).type == :contact

    assert Enum.at(result.tokens, 5).text ==
             "\nNext Level Productions\n1588 Mission Dr.\nSolvang, CA 93463"

    # First scene heading
    first_scene_index = 6
    assert Enum.at(result.tokens, first_scene_index).type == :scene_heading
    assert Enum.at(result.tokens, first_scene_index).text == "EXT. BRICK'S PATIO - DAY"

    # Action after first scene heading
    assert Enum.at(result.tokens, first_scene_index + 1).type == :action
    assert String.contains?(Enum.at(result.tokens, first_scene_index + 1).text, "A gorgeous day")

    # Find and validate first dialogue block
    first_dialogue_begin = find_first_dialogue_begin(result.tokens, first_scene_index + 2)
    assert first_dialogue_begin != nil
    validate_dialogue_block(result.tokens, first_dialogue_begin, "STEEL", "Beer's ready!")

    # Find and validate second dialogue block
    second_dialogue_begin = find_next_dialogue_begin(result.tokens, first_dialogue_begin + 1)
    assert second_dialogue_begin != nil
    validate_dialogue_block(result.tokens, second_dialogue_begin, "BRICK", "Are they cold?")

    # Find and validate dialogue block with parenthetical
    parenthetical_dialogue_begin =
      find_dialogue_with_parenthetical(result.tokens, second_dialogue_begin + 1)

    assert parenthetical_dialogue_begin != nil

    validate_dialogue_block_with_parenthetical(
      result.tokens,
      parenthetical_dialogue_begin,
      "STEEL",
      "(beer raised)",
      "To retirement."
    )

    # Find and validate transition
    transition_index = find_first_transition(result.tokens)
    assert transition_index != nil
    assert Enum.at(result.tokens, transition_index).type == :transition
    assert Enum.at(result.tokens, transition_index).text == "SMASH CUT TO:"

    # Test dual dialogue structure
    dual_dialogue_index = find_dual_dialogue(result.tokens)
    assert dual_dialogue_index != nil

    # Validate dual dialogue block structure
    assert Enum.at(result.tokens, dual_dialogue_index).type == :dual_dialogue_begin
    assert Enum.at(result.tokens, dual_dialogue_index + 1).type == :dialogue_begin
    assert Enum.at(result.tokens, dual_dialogue_index + 1).dual == true
    assert Enum.at(result.tokens, dual_dialogue_index + 2).type == :character
    assert Enum.at(result.tokens, dual_dialogue_index + 2).text == "BRICK"
    assert Enum.at(result.tokens, dual_dialogue_index + 3).type == :dialogue
    assert Enum.at(result.tokens, dual_dialogue_index + 3).text == "Screw retirement."
    assert Enum.at(result.tokens, dual_dialogue_index + 4).type == :dialogue_end
    assert Enum.at(result.tokens, dual_dialogue_index + 5).type == :dual_dialogue_end

    # Test that we have multiple scene headings
    scene_headings = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
    assert length(scene_headings) > 5

    # Test that we have multiple dialogue blocks
    dialogue_begins = Enum.filter(result.tokens, fn token -> token.type == :dialogue_begin end)
    assert length(dialogue_begins) > 10

    # Test that we have character names
    characters = Enum.filter(result.tokens, fn token -> token.type == :character end)
    character_names = Enum.map(characters, fn token -> token.text end) |> Enum.uniq()

    # Verify expected characters are present
    assert "BRICK" in character_names
    assert "STEEL" in character_names
    assert "JACK" in character_names
    assert "DAN" in character_names
    assert "COGNITO" in character_names
    assert "MINION" in character_names

    # Test that we have transitions
    transitions = Enum.filter(result.tokens, fn token -> token.type == :transition end)
    assert length(transitions) > 5

    # Test that we have parentheticals
    parentheticals = Enum.filter(result.tokens, fn token -> token.type == :parenthetical end)
    assert length(parentheticals) > 0

    # Test that we have action lines
    actions = Enum.filter(result.tokens, fn token -> token.type == :action end)
    assert length(actions) >= 20

    # Test for dual dialogue (BRICK ^)
    dual_dialogue_begins =
      Enum.filter(result.tokens, fn token -> token.type == :dual_dialogue_begin end)

    assert length(dual_dialogue_begins) > 0

    # Test scene headings - verify we have the expected ones
    scene_headings = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
    scene_heading_texts = Enum.map(scene_headings, fn token -> token.text end)

    # Verify expected scene headings are present
    assert "EXT. BRICK'S PATIO - DAY" in scene_heading_texts
    assert "INT. TRAILER HOME - DAY" in scene_heading_texts
    assert "EXT. BRICK'S POOL - DAY" in scene_heading_texts
    assert "SNIPER SCOPE POV" in scene_heading_texts
    assert "OPENING TITLES" in scene_heading_texts
    assert "EXT. WOODEN SHACK - DAY" in scene_heading_texts
    assert "INT. GARAGE - DAY" in scene_heading_texts
    assert "EXT. PALATIAL MANSION - DAY" in scene_heading_texts

    # Test for centered text
    centered_texts = Enum.filter(result.tokens, fn token -> token.type == :centered end)
    assert length(centered_texts) > 0

    # Verify specific centered text content (we know "THE END" exists)
    the_end_centered = Enum.find(centered_texts, fn token -> token.text == "THE END" end)
    assert the_end_centered != nil
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

  defp find_next_dialogue_begin(tokens, start_index) do
    tokens
    |> Enum.drop(start_index)
    |> Enum.find_index(fn token -> token.type == :dialogue_begin end)
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

  defp find_first_transition(tokens) do
    Enum.find_index(tokens, fn token -> token.type == :transition end)
  end

  defp find_dual_dialogue(tokens) do
    Enum.find_index(tokens, fn token ->
      token.type == :dual_dialogue_begin
    end)
  end

  defp validate_dialogue_block(tokens, start_index, expected_character, expected_dialogue) do
    assert Enum.at(tokens, start_index).type == :dialogue_begin
    assert Enum.at(tokens, start_index + 1).type == :character
    assert Enum.at(tokens, start_index + 1).text == expected_character
    assert Enum.at(tokens, start_index + 2).type == :dialogue
    assert Enum.at(tokens, start_index + 2).text == expected_dialogue
    assert Enum.at(tokens, start_index + 3).type == :dialogue_end
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
    assert Enum.at(tokens, start_index + 3).text == expected_dialogue
    assert Enum.at(tokens, start_index + 4).type == :dialogue_end
  end
end
