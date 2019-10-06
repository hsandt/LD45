-- usually we do not test data, and only test the data structures with mock data
--  but to simplify we put both actual data and data structure + methods in gameplay_data.lua
--  so it is more convenient to just test the access helpers with real data now

require("engine/test/bustedhelper")
local gameplay_data = require("resources/gameplay_data")

describe('gameplay_data', function ()

  describe('get_floor_info', function ()
    it('should return info for floor by index', function ()
      local f = gameplay_data:get_floor_info(3)

      -- very simple and incomplete test, but enough for this case
      assert.are_equal(3, f.number)
    end)
  end)

  describe('get_npc_info_table_with_level', function ()
    it('should return info for all npcs of a given level', function ()
      local npc_info_s_level3 = gameplay_data:get_npc_info_table_with_level(3)

      -- very simple and incomplete test, but enough for this case
      assert.are_equal(4, #npc_info_s_level3)
    end)
  end)

end)
