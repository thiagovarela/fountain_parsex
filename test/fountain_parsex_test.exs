defmodule FountainParsexTest do
  use ExUnit.Case
  doctest FountainParsex

  test "parses basic scene heading" do
    script = """
    EXT. HOUSE - DAY

    A beautiful day.
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 2
    assert Enum.at(result.tokens, 0).type == :scene_heading
    assert Enum.at(result.tokens, 0).text == "EXT. HOUSE - DAY"
    assert Enum.at(result.tokens, 1).type == :action
    assert Enum.at(result.tokens, 1).text == "A beautiful day."
  end

  test "parses character and dialogue" do
    script = """
    JOHN
    Hello, world!
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 4
    assert Enum.at(result.tokens, 0).type == :dialogue_begin
    assert Enum.at(result.tokens, 1).type == :character
    assert Enum.at(result.tokens, 1).text == "JOHN"
    assert Enum.at(result.tokens, 2).type == :dialogue
    assert Enum.at(result.tokens, 2).text == "Hello, world!"
    assert Enum.at(result.tokens, 3).type == :dialogue_end
  end

  test "parses title page" do
    script = """
    Title: My Script
    Author: John Doe
    """

    result = FountainParsex.parse(script)
    assert result.title == "My Script"

    # Assert tokens in correct order
    assert length(result.tokens) == 2
    assert Enum.at(result.tokens, 0).type == :title
    assert Enum.at(result.tokens, 0).text == "My Script"
    assert Enum.at(result.tokens, 1).type == :author
    assert Enum.at(result.tokens, 1).text == "John Doe"
  end

  test "parses parenthetical" do
    script = """
    JOHN
    (whispering)
    Hello, world!
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 5
    assert Enum.at(result.tokens, 0).type == :dialogue_begin
    assert Enum.at(result.tokens, 1).type == :character
    assert Enum.at(result.tokens, 1).text == "JOHN"
    assert Enum.at(result.tokens, 2).type == :parenthetical
    assert Enum.at(result.tokens, 2).text == "(whispering)"
    assert Enum.at(result.tokens, 3).type == :dialogue
    assert Enum.at(result.tokens, 3).text == "Hello, world!"
    assert Enum.at(result.tokens, 4).type == :dialogue_end
  end

  test "parses transition" do
    script = """
    CUT TO:
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 1
    assert Enum.at(result.tokens, 0).type == :transition
    assert Enum.at(result.tokens, 0).text == "CUT TO:"
  end

  test "parses forced scene heading" do
    script = """
    .CUSTOM SCENE
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 1
    assert Enum.at(result.tokens, 0).type == :scene_heading
    assert Enum.at(result.tokens, 0).text == "CUSTOM SCENE"
  end

  test "parses scene with scene number" do
    script = """
    EXT. HOUSE - DAY #1#
    """

    result = FountainParsex.parse(script)

    # Assert tokens in correct order
    assert length(result.tokens) == 1
    assert Enum.at(result.tokens, 0).type == :scene_heading
    assert Enum.at(result.tokens, 0).text == "EXT. HOUSE - DAY"
    assert Enum.at(result.tokens, 0).scene_number == "1"
  end
end
