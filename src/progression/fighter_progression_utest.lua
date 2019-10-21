require("engine/test/bustedhelper")
local fighter_progression = require("progression/fighter_progression")

local fighter_info = require("content/fighter_info")

require("engine/debug/logging")

describe('fighter_progression', function ()

  describe('_init', function ()
    it('should init a fighter_progression', function ()
      local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})
      local f_progression = fighter_progression(character_types.ai, mock_fighter_info)
      assert.are_same({
          character_types.ai,
          4,
          5,
          {11, 27},
          {12, 28},
          {2, 4},
          {},
          {}
        },
        {
          f_progression.character_type,
          f_progression.level,
          f_progression.max_hp,
          f_progression.known_attack_ids,
          f_progression.known_reply_ids,
          f_progression.known_quote_match_ids,
          f_progression.received_attack_id_count_persistent_map,
          f_progression.received_reply_id_count_persistent_map
        })
      assert.are_equal(mock_fighter_info, f_progression.fighter_info)
    end)
  end)

  describe('(with instance)', function ()

    local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})
    local f_progression

    before_each(function ()
      f_progression = fighter_progression(character_types.ai, mock_fighter_info)
    end)

    describe('(spying add_received_quote_id_count_map)', function ()

      setup(function ()
        stub(fighter_progression, "add_received_quote_id_count_map")
      end)

      teardown(function ()
        fighter_progression.add_received_quote_id_count_map:revert()
      end)

      after_each(function ()
        fighter_progression.add_received_quote_id_count_map:clear()
      end)

      describe('add_received_attack_id_count_map', function ()

        it('should call add_received_quote_id_count_map with self.received_attack_id_count_persistent_map and passed map', function ()
          local added_count_map = {}

          f_progression:add_received_attack_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.add_received_quote_id_count_map)
          s.was_called(1)
          s.was_called_with(match.ref(f_progression.received_attack_id_count_persistent_map), match.ref(added_count_map))
        end)

      end)

      describe('add_received_reply_id_count_map', function ()

        it('should call add_received_quote_id_count_map with self.received_reply_id_count_persistent_map and passed map', function ()
          local added_count_map = {}

          f_progression:add_received_reply_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.add_received_quote_id_count_map)
          s.was_called(1)
          s.was_called_with(match.ref(f_progression.received_reply_id_count_persistent_map), match.ref(added_count_map))
        end)

      end)

    end)

  end)  -- (with instance)

  -- static

  describe('add_received_quote_id_count_map', function ()

    it('should merge the count of both maps into the first map (empty)', function ()
      local modified_count_map = {}
      local added_count_map = {}

      fighter_progression.add_received_quote_id_count_map(modified_count_map, added_count_map)
      assert.are_same({}, modified_count_map)
    end)

    it('should merge the count of both maps into the first map (new item)', function ()
      local modified_count_map = {}
      local added_count_map = {[2] = 4}

      fighter_progression.add_received_quote_id_count_map(modified_count_map, added_count_map)
      assert.are_same({[2] = 4}, modified_count_map)
    end)

    it('should merge the count of both maps into the first map (sum)', function ()
      local modified_count_map = {[1] = 5, [2] = 6}
      local added_count_map = {[2] = 4, [3] = 7}

      fighter_progression.add_received_quote_id_count_map(modified_count_map, added_count_map)
      assert.are_same({[1] = 5, [2] = 10, [3] = 7}, modified_count_map)
    end)

  end)

end)
