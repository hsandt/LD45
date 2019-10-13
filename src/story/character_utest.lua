require("engine/test/bustedhelper")
local character = require("story/character")

require("engine/core/math")

local character_info = require("content/character_info")
local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

describe('character', function ()

  -- sprites character [8] must exist in visual_data
  local mock_character_info = character_info(2, "employee", 5)
  local pos = vector(20, 60)

  local c

  before_each(function ()
    c = character(mock_character_info, horizontal_dirs.right, pos)
  end)

  describe('_init', function ()
    it('should init a character', function ()
      assert.are_equal(mock_character_info, c.character_info)
      assert.are_equal(visual_data.sprites.character[5], c.sprite)
      local rel_bubble_tail_pos = visual_data.rel_bubble_tail_pos_by_horizontal_dir[horizontal_dirs.right]
      assert.are_same({
          speaker_component(pos + rel_bubble_tail_pos),
          pos
        },
        {c.speaker, c.pos})
    end)
  end)

  describe('draw', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        c:draw()
      end)
    end)
  end)

end)
