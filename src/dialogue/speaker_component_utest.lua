require("engine/test/bustedhelper")
local speaker_component = require("dialogue/speaker_component")

require("engine/core/math")

describe('speaker_component', function ()

  describe('_init', function ()
    it('should init a speaker_component', function ()
      local bubble_tail_pos = vector(-10, -30)
      local s = speaker_component(bubble_tail_pos)
      assert.are_same({bubble_tail_pos, nil}, {s.bubble_tail_pos, s.current_text})
    end)
  end)

end)
