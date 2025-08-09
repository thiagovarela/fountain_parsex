defmodule ScenesTest do
  use ExUnit.Case

  test "groups tokens into scenes correctly" do
    script = """
    Title: Test Script
    Author: Test Author

    EXT. HOUSE - DAY

    A beautiful day.

    JOHN
    Hello, world!

    INT. OFFICE - NIGHT

    Dark and quiet.

    JANE
    Good night.
    """

    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    # Should have 2 scenes
    assert length(scenes) == 2

    # First scene
    first_scene = Enum.at(scenes, 0)
    assert first_scene.heading.type == :scene_heading
    assert first_scene.heading.text == "EXT. HOUSE - DAY"
    
    # Check first scene content is text
    expected_content = "A beautiful day.\n\nJOHN\nHello, world!\n"
    assert first_scene.content == expected_content

    # Second scene
    second_scene = Enum.at(scenes, 1)
    assert second_scene.heading.type == :scene_heading
    assert second_scene.heading.text == "INT. OFFICE - NIGHT"
    
    # Check second scene content is text
    expected_content = "Dark and quiet.\n\nJANE\nGood night.\n"
    assert second_scene.content == expected_content
  end

  test "handles script without scene headings" do
    script = """
    Just some action text.

    JOHN
    Hello!
    """

    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    # Should have 1 scene without heading
    assert length(scenes) == 1

    scene = Enum.at(scenes, 0)
    assert scene.heading == nil
    
    # Check content is text
    expected_content = "Just some action text.\n\nJOHN\nHello!\n"
    assert scene.content == expected_content
  end

  test "handles empty script" do
    script = ""
    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    assert Enum.empty?(scenes)
  end

  test "handles script with only title page" do
    script = """
    Title: Test Script
    Author: Test Author
    """

    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    assert Enum.empty?(scenes)
  end

  test "preserves scene numbers in headings" do
    script = """
    EXT. HOUSE - DAY #1#

    Action here.
    """

    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    assert length(scenes) == 1
    scene = Enum.at(scenes, 0)
    assert scene.heading.type == :scene_heading
    assert scene.heading.text == "EXT. HOUSE - DAY"
    assert scene.heading.scene_number == "1"
  end

  test "handles complex scene with parentheticals" do
    script = """
    EXT. HOUSE - DAY

    JOHN
    (whispering)
    Hello.

    Some action here.
    """

    result = FountainParsex.parse(script)
    scenes = FountainParsex.scenes(result.tokens)

    assert length(scenes) == 1
    scene = Enum.at(scenes, 0)

    # Should contain text from action, character, parenthetical, and dialogue
    expected_content = "JOHN\n(whispering)\nHello.\n\nSome action here."
    assert scene.content == expected_content
  end
end
