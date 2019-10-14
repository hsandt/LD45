-- usually we do not test data, and only test the data structures with mock data
--  but to simplify we put both actual data and data structure + methods in gameplay_data.lua
--  so it is more convenient to just test the access helpers with real data now

require("engine/test/bustedhelper")
local gameplay_data = require("resources/gameplay_data")

describe('gameplay_data', function ()

  describe('are_quote_matching', function ()

    it('should return false if quotes are not matching', function ()
      local attack = gameplay_data.attacks[6]
      local reply = gameplay_data.replies[7]
      assert.is_false(gameplay_data:are_quote_matching(attack, reply))
    end)

    it('should return true if quotes are matching', function ()
      local attack = gameplay_data.attacks[7]
      local reply = gameplay_data.replies[7]
      assert.is_true(gameplay_data:are_quote_matching(attack, reply))
    end)

  end)

  describe('get_floor_info', function ()
    it('should return info for floor by index', function ()
      local f = gameplay_data:get_floor_info(3)

      -- very simple and incomplete test, but enough for this case
      assert.are_equal(3, f.number)
    end)
  end)

  describe('get_all_npc_fighter_info_with_level', function ()
    it('should return info for all npcs of a given level', function ()
      local npc_info_s_level3 = gameplay_data:get_all_npc_fighter_info_with_initial_level(3)

      -- very simple and incomplete test, but enough for this case
      assert.are_equal(4, #npc_info_s_level3)
    end)
  end)

end)
