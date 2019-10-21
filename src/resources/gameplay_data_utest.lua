-- usually we do not test data, and only test the data structures with mock data
--  but to simplify we put both actual data and data structure + methods in gameplay_data.lua
--  so it is more convenient to just test the access helpers with real data now

require("engine/test/bustedhelper")
local gameplay_data = require("resources/gameplay_data")

describe('gameplay_data', function ()

  describe('get_quote', function ()

    it('should quote info by type (attack) and id', function ()
      -- relies on having at least 3 attacks
      assert.are_equal(gameplay_data.attacks[3], gameplay_data:get_quote(quote_types.attack, 3))
    end)

    it('should quote info by type (reply) and id', function ()
      -- relies on having at least 3 replies
      assert.are_equal(gameplay_data.replies[3], gameplay_data:get_quote(quote_types.reply, 3))
    end)

  end)

  describe('get_quote_match_power', function ()

    it('should return 0 if using the cancel reply against anything', function ()
      local attack = gameplay_data.attacks[8]
      local reply = gameplay_data.replies[0]
      assert.are_equal(0, gameplay_data:get_quote_match_power(attack, reply))
    end)

    it('should return -1 if quotes are not matching', function ()
      local attack = gameplay_data.attacks[8]
      local reply = gameplay_data.replies[10]
      assert.are_equal(-1, gameplay_data:get_quote_match_power(attack, reply))
    end)

    it('should return match power if quotes are matching', function ()
      local attack = gameplay_data.attacks[8]
      local reply = gameplay_data.replies[11]
      assert.are_equal(2, gameplay_data:get_quote_match_power(attack, reply))
    end)

  end)

  describe('get_floor_info', function ()
    it('should return info for floor by index', function ()
      -- relies on having at least 3 floors
      assert.are_equal(gameplay_data.floors[3], gameplay_data:get_floor_info(3))
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
