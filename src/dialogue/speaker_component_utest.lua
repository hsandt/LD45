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
      assert.are_same({bubble_tail_pos, nil}, {s.bubble_tail_pos, s.current_text})
    end)
  end)

  describe('say', function ()

    it('should set the current speaker and the current text', function ()
      s:say("hello")

      assert.are_equal("hello", s.current_text)
    end)

  end)

  describe('stop', function ()

    it('should set the current speaker and the current text', function ()
      s.current_text = "hello"

      s:stop()

      assert.is_nil(s.current_text)
    end)

  end)

end)
