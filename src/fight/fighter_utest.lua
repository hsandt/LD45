require("engine/test/bustedhelper")
local fighter = require("fight/fighter")

local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local fighter_progression = require("progression/fighter_progression")
local character = require("story/character")

describe('fighter', function ()

  local mock_character_info = character_info(2, "employee", 5)
  local pos = vector(20, 60)
  local mock_character = character(mock_character_info, horizontal_dirs.right, pos)

  local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})
  local mock_fighter_progression = fighter_progression(character_types.ai, mock_fighter_info)

  local f

  before_each(function ()
    f = fighter(mock_character, mock_fighter_progression)
  end)

  describe('_init', function ()

    it('should init a fighter with character and progression refs', function ()
      assert.are_equal(mock_character, f.character)
      assert.are_equal(mock_progression_info, f.progression_info)
    end)

    it('should init a fighter', function ()
      assert.are_same({5, nil}, {f.hp, f.last_quote})
    end)

  end)

  describe('_tostring', function ()
    it('fighter(...) => "fighter(\"name\", hp={self.hp})"', function ()
      f.hp = 3
      assert.are_equal("[fighter(\"employee\", hp=3)]", f:_tostring())
    end)
  end)

  -- logic

  describe('take_damage', function ()

    it('should reduce the fighter hp', function ()
      f:take_damage(1)
      assert.are_equal(4, f.hp)
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
        f:draw()
      assert.has_no_errors(function ()
        f:draw()
      end)
    end)
  end)

end)
