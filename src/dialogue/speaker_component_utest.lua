require("engine/test/bustedhelper")
local speaker_component = require("dialogue/speaker_component")

local animated_sprite = require("engine/render/animated_sprite")

local character_info = require("content/character_info")
local visual_data = require("resources/visual_data")
local character = require("story/character")

require("engine/core/math")

describe('speaker_component', function ()

  local mock_character_info = character_info(2, "employee", 5)

  local c
  local s

  before_each(function ()
    c = character(mock_character_info, horizontal_dirs.right, vector(20, 60))
    s = speaker_component(c)
  end)

  describe('_init', function ()
    it('should init a speaker_component', function ()
      assert.are_equal(c, s.entity)
      assert.are_same({animated_sprite(visual_data.anim_sprites.button_o), bubble_types.speech, nil, false, false},
        {s.continue_hint_sprite, s.bubble_type, s.current_text, s.wait_for_input, s.higher_text})
    end)
  end)

  describe('get_final_bubble_tail_pos', function ()

    it('(right, speech, not higher text) should return speech bubble tail pos', function ()
      s.bubble_type = bubble_types.speech
      s.current_text = "hello"
      s.higher_text = false

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.speech]
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('(right, speech, higher text) should return speech bubble tail pos + first speaker offset', function ()
      s.bubble_type = bubble_types.speech
      s.current_text = "hello"
      s.higher_text = true

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.speech]
      expected_bubble_tail_pos = expected_bubble_tail_pos + vector(0, visual_data.first_speaker_tail_offset_y)
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('(right, thought, not higher text) should return thought bubble tail pos', function ()
      s.bubble_type = bubble_types.thought
      s.current_text = "hello"
      s.higher_text = false

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.thought]
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('(left, speech, higher text) should return speech bubble tail pos (mirrored x) + first speaker offset', function ()
      c.direction = horizontal_dirs.left
      s.bubble_type = bubble_types.speech
      s.current_text = "hello"
      s.higher_text = true

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.speech]:mirrored_x()
      expected_bubble_tail_pos = expected_bubble_tail_pos + vector(0, visual_data.first_speaker_tail_offset_y)
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('(left, thought, not higher text) should return thought bubble tail pos (mirrored x)', function ()
      c.direction = horizontal_dirs.left
      s.bubble_type = bubble_types.thought
      s.current_text = "hello"
      s.higher_text = false

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.thought]:mirrored_x()
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('(left, thought, higher text) should return thought bubble tail pos (mirrored x) + first speaker offset', function ()
      c.direction = horizontal_dirs.left
      s.bubble_type = bubble_types.thought
      s.current_text = "hello"
      s.higher_text = true

      local expected_bubble_tail_pos = vector(20, 60) + visual_data.bubble_tail_offset_right_by_bubble_type[bubble_types.thought]:mirrored_x()
      expected_bubble_tail_pos = expected_bubble_tail_pos + vector(0, visual_data.first_speaker_tail_offset_y)
      assert.are_equal(expected_bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

  end)

  describe('say & think', function ()

    setup(function ()
      stub(speaker_component, "show_bubble")
    end)

    teardown(function ()
      speaker_component.show_bubble:revert()
    end)

    after_each(function ()
      speaker_component.show_bubble:clear()
    end)

    it('say should call show_bubble with speech bubble type', function ()
      s:say("hello", false, true)

      local spy = assert.spy(speaker_component.show_bubble)
      spy.was_called(1)
      spy.was_called_with(match.ref(s), bubble_types.speech, "hello", false, true)
    end)

    it('think should call show_bubble with speech bubble type', function ()
      s:think("hello", false, true)

      local spy = assert.spy(speaker_component.show_bubble)
      spy.was_called(1)
      spy.was_called_with(match.ref(s), bubble_types.thought, "hello", false, true)
    end)

  end)

  describe('show_bubble', function ()

    setup(function ()
      stub(animated_sprite, "play")
    end)

    teardown(function ()
      animated_sprite.play:revert()
    end)

    after_each(function ()
      animated_sprite.play:clear()
    end)

    it('should set the bubble type and the current text with wait_for_input = false and higher_text = false by default', function ()
      s:show_bubble(bubble_types.thought, "hello")

      assert.are_same({bubble_types.thought, "hello", false, false}, {s.bubble_type, s.current_text, s.wait_for_input, s.higher_text})
    end)

    it('should set wait_for_input to the passed value', function ()
      s:show_bubble(bubble_types.speech, "hello", true)

      assert.is_true(s.wait_for_input)
    end)

    it('should set higher_text to the passed value', function ()
      s:show_bubble(bubble_types.thought, "hello", nil, true)

      assert.is_true(s.higher_text)
    end)

    it('should play continue hint sprite press_loop anim if waiting for input', function ()
      -- animated_sprite.play is called in character:_init (before_each), so clear call count now
      animated_sprite.play:clear()

      s:show_bubble(bubble_types.thought, "hello", true)

      local spy = assert.spy(animated_sprite.play)
      spy.was_called(1)
      spy.was_called_with(match.ref(s.continue_hint_sprite), 'press_loop')
    end)

    it('should not play continue hint sprite press_loop anim if not waiting for input', function ()
      -- animated_sprite.play is called in character:_init (before_each), so clear call count now
      animated_sprite.play:clear()

      s:show_bubble(bubble_types.thought, "hello", false)

      local spy = assert.spy(animated_sprite.play)
      spy.was_not_called()
    end)

  end)

  describe('stop', function ()

    setup(function ()
      stub(animated_sprite, "stop")
    end)

    teardown(function ()
      animated_sprite.stop:revert()
    end)

    after_each(function ()
      animated_sprite.stop:clear()
    end)

    it('should reset the current text and wait_for_input', function ()
      s.current_text = "hello"
      s.wait_for_input = true

      s:stop()

      assert.are_same({nil, false}, {s.current_text, s.wait_for_input})

      local spy = assert.spy(animated_sprite.stop)
      spy.was_called(1)
      spy.was_called_with(match.ref(s.continue_hint_sprite))
    end)

  end)

end)
