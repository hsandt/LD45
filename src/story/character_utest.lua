require("engine/test/bustedhelper")
local character = require("story/character")

require("engine/core/math")
local sprite_data = require("engine/render/sprite_data")

local speaker_component = require("dialogue/speaker_component")

describe('character', function ()

  local mock_sprite = sprite_data(sprite_id_location(1, 3))
  local pos = vector(20, 60)
  local rel_bubble_tail_pos = vector(2, -20)

  local c

  before_each(function ()
    c = character(mock_sprite, pos, rel_bubble_tail_pos)
  end)

  describe('_init', function ()
    it('should init a character', function ()
      assert.are_same({speaker_component(pos + rel_bubble_tail_pos), mock_sprite, pos}, {c.speaker, c.sprite, c.pos})
    end)
  end)

  describe('draw', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        c:draw()
      end)
    end)
  end)

  describe('say', function ()

    it('should set the current speaker and the current text', function ()
      c:say("hello")

      assert.are_equal("hello", c.current_text)
    end)

  end)

end)
