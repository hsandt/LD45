require("engine/test/bustedhelper")
local fighter = require("fight/fighter")

require("engine/core/math")
local sprite_data = require("engine/render/sprite_data")

describe('fighter', function ()

  local mock_sprite = sprite_data(sprite_id_location(1, 3))

  local f

  before_each(function ()
    f = fighter(control_types.ai, 100, mock_sprite, vector(20, 40), horizontal_dirs.right)
  end)

  describe('_init', function ()
    it('should init a fighter', function ()
      assert.are_same({control_types.ai, 100, mock_sprite, vector(20, 40), horizontal_dirs.right}, {f.control_type, f.hp, f.sprite, f.pos, f.direction})
    end)
  end)

  describe('_tostring', function ()
    it('fighter(...) => "fighter(...)"', function ()
      assert.are_equal("fighter(2, 100, sprite_data(sprite_id_location(1, 3), tile_vector(1, 1), vector(0, 0), 0), vector(20, 40), 2)", f:_tostring())
    end)
  end)

  -- logic

  describe('take_damage', function ()

    it('should reduce the fighter hp', function ()
      f:take_damage(5)
      assert.are_equal(95, f.hp)
    end)

    it('should clamp the reduced hp at 0', function ()
      f:take_damage(200)
      assert.are_equal(0, f.hp)
    end)

  end)

  describe('is_alive', function ()

    it('should return true if hp > 0', function ()
      f.hp = 1
      assert.is_true(f:is_alive())
    end)

    it('should return true if hp <= 0', function ()
      f.hp = 0
      assert.is_false(f:is_alive())
    end)

  end)

  -- render

  describe('draw', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        f:draw()
      end)
    end)
  end)

end)
