require("engine/test/bustedhelper")
local speaker_component = require("dialogue/speaker_component")

require("engine/core/math")

describe('speaker_component', function ()

  local bubble_tail_pos = vector(-10, -30)

  local s

  before_each(function ()
    s = speaker_component(bubble_tail_pos)
  end)

  describe('_init', function ()
    it('should init a speaker_component', function ()
      assert.are_same({bubble_tail_pos, nil, false}, {s.bubble_tail_pos, s.current_text, s.wait_for_input})
    end)
  end)

  describe('say', function ()

    it('should set the current speaker and the current text with wait_for_input = false by default', function ()
      s:say("hello")

      assert.are_same({"hello", false}, {s.current_text, s.wait_for_input})
    end)

    it('should set wait_for_input to the passed value', function ()
      s:say("hello", true)

      assert.is_true(s.wait_for_input)
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
