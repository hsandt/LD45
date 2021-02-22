require("test/bustedhelper_game")
local floor_info = require("content/floor_info")

describe('floor_info', function ()

  describe('init', function ()
    it('should init a floor_info with number and npc level range', function ()
      local f = floor_info(12, 4, 6)
      assert.are_same({12, 4, 6}, {f.number, f.npc_level_min, f.npc_level_max})
    end)
  end)

  describe('_tostring', function ()
    it('floor_info(12, 4, 6) => "floor_info(12, 4, 6)"', function ()
      local f = floor_info(12, 4, 6)
      assert.are_equal("floor_info(12, 4, 6)", f:_tostring())
    end)
  end)

end)
