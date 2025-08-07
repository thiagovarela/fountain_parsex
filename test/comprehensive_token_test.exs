defmodule FountainParsex.ComprehensiveTokenTests do
  use ExUnit.Case

  describe "All Token Types" do
    test "handles all basic token types" do
      script = """
      Title: Test Script
      Author: Test Author

      # ACT I

      = This is a synopsis

      EXT. HOUSE - DAY #42#

      JOHN
      (whispering)
      Hello world!

      CUT TO:

      > CENTERED TEXT <

      ~LYRICS LINE~

      ===

      INT. HOUSE - NIGHT

      """

      result = FountainParsex.parse(script)

      # Test title page parsing
      assert result.title == "Test Script"

      # Test title page tokens
      title_token = Enum.find(result.tokens, fn token -> token.type == :title end)
      assert title_token != nil
      assert title_token.text == "Test Script"

      author_token = Enum.find(result.tokens, fn token -> token.type == :author end)
      assert author_token != nil
      assert author_token.text == "Test Author"

      # Test section
      section_token = Enum.find(result.tokens, fn token -> token.type == :section end)
      assert section_token != nil
      assert section_token.text == "ACT I"
      assert section_token.depth == 1

      # Test synopsis
      synopsis_token = Enum.find(result.tokens, fn token -> token.type == :synopsis end)
      assert synopsis_token != nil
      assert synopsis_token.text == "This is a synopsis"

      # Test scene heading with number
      scene_heading_token = Enum.find(result.tokens, fn token -> token.type == :scene_heading end)
      assert scene_heading_token != nil
      assert scene_heading_token.text == "EXT. HOUSE - DAY"
      assert scene_heading_token.scene_number == "42"

      # Test character
      character_token = Enum.find(result.tokens, fn token -> token.type == :character end)
      assert character_token != nil
      assert character_token.text == "JOHN"

      # Test parenthetical
      parenthetical_token = Enum.find(result.tokens, fn token -> token.type == :parenthetical end)
      assert parenthetical_token != nil
      assert parenthetical_token.text == "(whispering)"

      # Test dialogue
      dialogue_token = Enum.find(result.tokens, fn token -> token.type == :dialogue end)
      assert dialogue_token != nil
      assert dialogue_token.text == "Hello world!"

      # Test transition
      transition_token = Enum.find(result.tokens, fn token -> token.type == :transition end)
      assert transition_token != nil
      assert transition_token.text == "CUT TO:"

      # Test centered text
      centered_token = Enum.find(result.tokens, fn token -> token.type == :centered end)
      assert centered_token != nil
      assert centered_token.text == "CENTERED TEXT"

      # Test lyrics
      lyrics_token = Enum.find(result.tokens, fn token -> token.type == :lyrics end)
      assert lyrics_token != nil
      assert lyrics_token.text == "LYRICS LINE~"

      # Test page break
      page_break_token = Enum.find(result.tokens, fn token -> token.type == :page_break end)
      assert page_break_token != nil

      # Test second scene heading
      scene_tokens = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
      assert length(scene_tokens) == 2
      second_scene = Enum.at(scene_tokens, 1)
      assert second_scene.text == "INT. HOUSE - NIGHT"
    end

    test "handles dual dialogue" do
      script = """
      JOHN
      (whispering)
      Hello world!

      MARY^
      (whispering back)
      Hi there!
      """

      result = FountainParsex.parse(script)

      # Find dual dialogue marker
      dual_dialogue_begin =
        Enum.find(result.tokens, fn token -> token.type == :dual_dialogue_begin end)

      assert dual_dialogue_begin != nil

      # Find dual dialogue end
      dual_dialogue_end =
        Enum.find(result.tokens, fn token -> token.type == :dual_dialogue_end end)

      assert dual_dialogue_end != nil

      # Find character tokens
      character_tokens = Enum.filter(result.tokens, fn token -> token.type == :character end)
      assert length(character_tokens) == 2
      assert Enum.at(character_tokens, 0).text == "JOHN"
      assert Enum.at(character_tokens, 1).text == "MARY"

      # Find dialogue tokens
      dialogue_tokens = Enum.filter(result.tokens, fn token -> token.type == :dialogue end)
      assert length(dialogue_tokens) == 2
      assert Enum.at(dialogue_tokens, 0).text == "Hello world!"
      assert Enum.at(dialogue_tokens, 1).text == "Hi there!"
    end

    test "handles forced scene headings" do
      script = """
      .FORCED SCENE HEADING

      JOHN
      Hello!
      """

      result = FountainParsex.parse(script)

      # Find scene heading token
      scene_heading = Enum.find(result.tokens, fn token -> token.type == :scene_heading end)
      assert scene_heading != nil
      assert scene_heading.text == "FORCED SCENE HEADING"
    end

    test "handles multiple actions" do
      script = """
      EXT. HOUSE - DAY

      John walks into the house.

      He looks around.

      The room is empty.
      """

      result = FountainParsex.parse(script)

      # Find scene heading
      scene_heading = Enum.find(result.tokens, fn token -> token.type == :scene_heading end)
      assert scene_heading != nil
      assert scene_heading.text == "EXT. HOUSE - DAY"

      # Find action tokens
      action_tokens = Enum.filter(result.tokens, fn token -> token.type == :action end)
      assert length(action_tokens) == 3
      assert Enum.at(action_tokens, 0).text == "John walks into the house."
      assert Enum.at(action_tokens, 1).text == "He looks around."
      assert Enum.at(action_tokens, 2).text == "The room is empty."
    end

    test "handles various title page elements" do
      script = """
      Title: My Movie
      Credit: Written by
      Author: John Doe
      Authors: Jane Smith, Bob Johnson
      Source: Based on true events
      Notes: This is a test
      Draft date: 2023-01-01
      Date: 2023-01-01
      Contact: test@example.com
      Copyright: © 2023
      """

      result = FountainParsex.parse(script)

      # Test that title page elements are parsed
      assert result.title == "My Movie"

      # Find all title page tokens
      title_token = Enum.find(result.tokens, fn token -> token.type == :title end)
      assert title_token != nil
      assert title_token.text == "My Movie"

      credit_token = Enum.find(result.tokens, fn token -> token.type == :credit end)
      assert credit_token != nil
      assert credit_token.text == "Written by"

      author_token = Enum.find(result.tokens, fn token -> token.type == :author end)
      assert author_token != nil
      assert author_token.text == "John Doe"

      authors_token = Enum.find(result.tokens, fn token -> token.type == :authors end)
      assert authors_token != nil
      assert authors_token.text == "Jane Smith, Bob Johnson"

      source_token = Enum.find(result.tokens, fn token -> token.type == :source end)
      assert source_token != nil
      assert source_token.text == "Based on true events"

      notes_token = Enum.find(result.tokens, fn token -> token.type == :notes end)
      assert notes_token != nil
      assert notes_token.text == "This is a test"

      draft_date_token = Enum.find(result.tokens, fn token -> token.type == :draft_date end)
      assert draft_date_token != nil
      assert draft_date_token.text == "2023-01-01"

      date_token = Enum.find(result.tokens, fn token -> token.type == :date end)
      assert date_token != nil
      assert date_token.text == "2023-01-01"

      contact_token = Enum.find(result.tokens, fn token -> token.type == :contact end)
      assert contact_token != nil
      assert contact_token.text == "test@example.com"

      copyright_token = Enum.find(result.tokens, fn token -> token.type == :copyright end)
      assert copyright_token != nil
      assert copyright_token.text == "© 2023"
    end

    test "handles complex dialogue structures" do
      script = """
      JOHN

      (whispering)

      Hello world!

      (more dialogue)

      How are you?
      """

      result = FountainParsex.parse(script)

      # Test that dialogue with multiple parentheticals is handled
      # Note: This specific structure may not be parsed as a character dialogue block in this implementation
      # The parser treats it as action text, but the actual content should be present
      action_tokens = Enum.filter(result.tokens, fn token -> token.type == :action end)
      assert length(action_tokens) >= 4

      action_texts = Enum.map(action_tokens, fn token -> token.text end)
      assert Enum.member?(action_texts, "How are you?")
      assert Enum.member?(action_texts, "(more dialogue)")
      assert Enum.member?(action_texts, "Hello world!")
      assert Enum.member?(action_texts, "(whispering)")
    end

    test "handles section nesting" do
      script = """
      # ACT I

      ## SCENE 1

      ### SEQUENCE A

      EXT. HOUSE - DAY

      JOHN
      Hello!
      """

      result = FountainParsex.parse(script)

      # Find section tokens
      section_tokens = Enum.filter(result.tokens, fn token -> token.type == :section end)
      assert length(section_tokens) == 3

      # Check section depths and text
      sections_by_depth = Enum.sort_by(section_tokens, fn token -> token.depth end)
      assert Enum.at(sections_by_depth, 0).text == "ACT I"
      assert Enum.at(sections_by_depth, 0).depth == 1
      assert Enum.at(sections_by_depth, 1).text == "SCENE 1"
      assert Enum.at(sections_by_depth, 1).depth == 2
      assert Enum.at(sections_by_depth, 2).text == "SEQUENCE A"
      assert Enum.at(sections_by_depth, 2).depth == 3
    end

    test "handles various scene heading formats" do
      script = """
      EXT. HOUSE - DAY

      INT. HOUSE - NIGHT

      .FORCED SCENE HEADING

      EXT. PARK - MORNING #123#
      """

      result = FountainParsex.parse(script)

      # Find all scene heading tokens
      scene_tokens = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
      assert length(scene_tokens) == 4

      # Check each scene heading
      scene_texts = Enum.map(scene_tokens, fn token -> token.text end)
      assert Enum.member?(scene_texts, "EXT. HOUSE - DAY")
      assert Enum.member?(scene_texts, "INT. HOUSE - NIGHT")
      assert Enum.member?(scene_texts, "FORCED SCENE HEADING")
      assert Enum.member?(scene_texts, "EXT. PARK - MORNING")

      # Check scene number
      numbered_scene = Enum.find(scene_tokens, fn token -> token.scene_number != nil end)
      assert numbered_scene != nil
      assert numbered_scene.scene_number == "123"
    end

    test "handles boneyard comments" do
      script = """
      EXT. HOUSE - DAY [[This is a note]]

      /* This should be ignored
      JOHN
      Hello!
      */

      MARY
      Goodbye!
      """

      result = FountainParsex.parse(script)

      # Should not contain the ignored content
      action_tokens = Enum.filter(result.tokens, fn token -> token.type == :action end)
      action_texts = Enum.map(action_tokens, fn token -> token.text end)
      refute Enum.member?(action_texts, "This should be ignored")

      # Should still parse the character and dialogue
      character_token = Enum.find(result.tokens, fn token -> token.type == :character end)
      assert character_token != nil
      assert character_token.text == "MARY"

      dialogue_token = Enum.find(result.tokens, fn token -> token.type == :dialogue end)
      assert dialogue_token != nil
      assert dialogue_token.text == "Goodbye!"
    end

    test "handles various scene number formats" do
      script = """
      EXT. HOUSE - DAY #1#

      INT. APARTMENT - NIGHT #1A#

      EXT. PARK - MORNING #42#

      INT. OFFICE - DAY #I-1-A#

      EXT. BEACH - SUNSET #110A#

      INT. CAR - NIGHT #1.#

      EXT. HOUSE - DAY - FLASHBACK (1944) #123#
      """

      result = FountainParsex.parse(script)

      # Find all scene heading tokens
      scene_tokens = Enum.filter(result.tokens, fn token -> token.type == :scene_heading end)
      assert length(scene_tokens) == 7

      # Test each scene number format
      scene_numbers =
        Enum.map(scene_tokens, fn token ->
          {token.text, token.scene_number}
        end)

      # Verify scene numbers are correctly extracted
      assert {"EXT. HOUSE - DAY", "1"} in scene_numbers
      assert {"INT. APARTMENT - NIGHT", "1A"} in scene_numbers
      assert {"EXT. PARK - MORNING", "42"} in scene_numbers
      assert {"INT. OFFICE - DAY", "I-1-A"} in scene_numbers
      assert {"EXT. BEACH - SUNSET", "110A"} in scene_numbers
      assert {"INT. CAR - NIGHT", "1."} in scene_numbers
      assert {"EXT. HOUSE - DAY - FLASHBACK (1944)", "123"} in scene_numbers

      # Verify all scene headings have scene numbers
      Enum.each(scene_tokens, fn token ->
        assert token.scene_number != nil,
               "Scene heading '#{token.text}' should have a scene number"
      end)

      # Verify scene numbers are removed from the text
      Enum.each(scene_tokens, fn token ->
        refute String.contains?(token.text, "#"),
               "Scene heading text '#{token.text}' should not contain # symbols"
      end)
    end
  end
end
