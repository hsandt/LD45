require("engine/test/bustedhelper")
local fighter = require("fight/fighter")

require("engine/core/math")
local sprite_data = require("engine/render/sprite_data")

describe('fighter', function ()

  describe('_init', function ()
    it('should init a fighter', function ()
      local mock_sprite = sprite_data(sprite_id_location(1, 3))
      local f = fighter(100, mock_sprite, vector(20, 40), horizontal_dirs.right)
      assert.are_same({100, mock_sprite, vector(20, 40), horizontal_dirs.right}, {f.hp, f.sprite, f.pos, f.direction})
    end)
  end)

  describe('_tostring', function ()
    it('fighter(100) => "fighter(100)"', function ()
      local mock_sprite = sprite_data(sprite_id_location(1, 3))
      local f = fighter(100, mock_sprite, vector(20, 40), horizontal_dirs.right)
      assert.are_equal("fighter(100, sprite_data(sprite_id_location(1, 3), tile_vector(1, 1), vector(0, 0), 0), vector(20, 40), 2)", f:_tostring())
    end)
  end)

  describe('draw', function ()
    it('should not error', function ()
      local mock_sprite = sprite_data(sprite_id_location(1, 3))
      local f = fighter(100, mock_sprite, vector(20, 40), horizontal_dirs.right)
      assert.has_no_errors(function ()
        f:draw()
      end)
    end)
  end)

end)