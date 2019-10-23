require("engine/test/bustedhelper")
local speaker_component = require("dialogue/speaker_component")

local visual_data = require("resources/visual_data")

require("engine/core/math")

describe('speaker_component', function ()

  local bubble_tail_pos = vector(-10, -30)

  local s

  before_each(function ()
    s = speaker_component(bubble_tail_pos)
  end)

  describe('_init', function ()
    it('should init a speaker_component', function ()
      assert.are_same({bubble_tail_pos, nil, false, false},
        {s.bubble_tail_pos, s.current_text, s.wait_for_input, s.higher_text})
    end)
  end)

  describe('get_final_bubble_tail_pos', function ()

    it('should return the bubble tail pos if not saying higher text', function ()
      s.current_text = "hello"
      s.higher_text = false

      assert.are_equal(bubble_tail_pos, s:get_final_bubble_tail_pos())
    end)

    it('should return the bubble tail pos + first speaker offset if not saying higher text', function ()
      s.current_text = "hello"
      s.higher_text = true

      assert.are_equal(bubble_tail_pos + vector(0, visual_data.first_speaker_tail_offset_y),
        s:get_final_bubble_tail_pos())
    end)

  end)

  describe('say', function ()

    it('should set the current speaker and the current text with wait_for_input = false and higher_text = false by default', function ()
      s:say("hello")

      assert.are_same({"hello", false, false}, {s.current_text, s.wait_for_input, s.higher_text})
    end)

    it('should set wait_for_input to the passed value', function ()
      s:say("hello", true)

      assert.is_true(s.wait_for_input)
    end)

    it('should set higher_text to the passed value', function ()
      s:say("hello", nil, true)

      assert.is_true(s.higher_text)
    end)

  end)

  describe('stop', function ()

    it('should reset the current text and wait_for_input', function ()
      s.current_text = "hello"
      s.wait_for_input = true

      s:stop()

      assert.are_same({nil, false}, {s.current_text, s.wait_for_input})
    end)

  end)

end)
