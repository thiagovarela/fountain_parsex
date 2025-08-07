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
    # action, dialogue_begin, character, dialogue, dialogue_end
    assert length(first_scene.content) == 5

    # Check first scene content
    assert Enum.at(first_scene.content, 0).type == :action
    assert Enum.at(first_scene.content, 0).text == "A beautiful day."
    assert Enum.at(first_scene.content, 1).type == :dialogue_begin
    assert Enum.at(first_scene.content, 2).type == :character
    assert Enum.at(first_scene.content, 2).text == "JOHN"
    assert Enum.at(first_scene.content, 3).type == :dialogue
    assert Enum.at(first_scene.content, 3).text == "Hello, world!"
    assert Enum.at(first_scene.content, 4).type == :dialogue_end

    # Second scene
    second_scene = Enum.at(scenes, 1)
    assert second_scene.heading.type == :scene_heading
    assert second_scene.heading.text == "INT. OFFICE - NIGHT"
    # action, dialogue_begin, character, dialogue, dialogue_end
    assert length(second_scene.content) == 5

    # Check second scene content
    assert Enum.at(second_scene.content, 0).type == :action
    assert Enum.at(second_scene.content, 0).text == "Dark and quiet."
    assert Enum.at(second_scene.content, 1).type == :dialogue_begin
    assert Enum.at(second_scene.content, 2).type == :character
    assert Enum.at(second_scene.content, 2).text == "JANE"
    assert Enum.at(second_scene.content, 3).type == :dialogue
    assert Enum.at(second_scene.content, 3).text == "Good night."
    assert Enum.at(second_scene.content, 4).type == :dialogue_end
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
    # action, dialogue_begin, character, dialogue, dialogue_end
    assert length(scene.content) == 5
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

    # Should contain action, dialogue blocks, and parentheticals
    content_types = Enum.map(scene.content, fn token -> token.type end)
    assert :action in content_types
    assert :dialogue_begin in content_types
    assert :character in content_types
    assert :parenthetical in content_types
    assert :dialogue in content_types
    assert :dialogue_end in content_types
  end
end
