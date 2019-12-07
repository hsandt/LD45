-- usually we do not test data, and only test the data structures with mock data
--  but to simplify we put both actual data and data structure + methods in gameplay_data.lua
--  so it is more convenient to just test the access helpers with real data now

require("engine/test/bustedhelper")
local gameplay_data = require("resources/gameplay_data")

local quote_match_info = require("content/quote_match_info")

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

  describe('get_quote_match', function ()

    setup(function ()
      stub(gameplay_data, "get_quote_match_with_id", function (self, attack_id, reply_id)
        return quote_match_info(77, attack_id, reply_id, 99)
      end)
    end)

    teardown(function ()
      gameplay_data.get_quote_match_with_id:revert()
    end)

    it('should return get_quote_match_with_id applied to the attack and reply ids', function ()
      local attack = gameplay_data.attacks[8]
      local reply = gameplay_data.replies[0]
      assert.are_same(quote_match_info(77, 8, 0, 99), gameplay_data:get_quote_match(attack, reply))
    end)

  end)

  describe('get_quote_match_with_id', function ()

    it('should return cancel_quote_match (power 0) if using the cancel reply against anything', function ()
      -- ! gameplay_data-dependent !
      assert.are_equal(gameplay_data.cancel_quote_match, gameplay_data:get_quote_match_with_id(8, 0))
    end)

    it('should return nil if quotes are not matching', function ()
      -- ! gameplay_data-dependent !
      assert.is_nil(gameplay_data:get_quote_match_with_id(8, 10))
    end)

    it('should return match power if quotes are matching', function ()
      -- ! gameplay_data-dependent !
      assert.are_equal(gameplay_data.quote_matches[24], gameplay_data:get_quote_match_with_id(8, 11))
    end)

  end)

  describe('get_floor_info', function ()
    it('should return info for floor by index', function ()
      -- relies on having at least 3 floors
      assert.are_equal(gameplay_data.floors[3], gameplay_data:get_floor_info(3))
    end)
  end)

  describe('get_zone', function ()

    -- ! data-dependent !

    it('should assert', function ()
      assert.has_error(function ()
        gameplay_data:get_zone(0)
      end)
    end)

    it('should return 1 for floor 1', function ()
      assert.are_equal(1, gameplay_data:get_zone(1))
    end)

    it('should return 1 for floor 2', function ()
      assert.are_equal(1, gameplay_data:get_zone(2))
    end)

    it('should return 2 for floor 3', function ()
      assert.are_equal(2, gameplay_data:get_zone(3))
    end)

    it('should return 2 for floor 4', function ()
      assert.are_equal(2, gameplay_data:get_zone(4))
    end)

    it('should return 3 for floor 5', function ()
      assert.are_equal(3, gameplay_data:get_zone(5))
    end)

    it('should return 4 for floor 6', function ()
      assert.are_equal(4, gameplay_data:get_zone(6))
    end)

  end)

  describe('get_all_npc_fighter_info_with_level', function ()
    it('should return info for all npcs of a given level', function ()
      local npc_info_s_level3 = gameplay_data:get_all_npc_fighter_info_with_initial_level(1)

      -- very simple and incomplete test, but enough for this case
      assert.are_equal(2, #npc_info_s_level3)
    end)
  end)

end)
