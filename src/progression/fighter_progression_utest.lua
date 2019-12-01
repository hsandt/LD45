require("engine/test/bustedhelper")
local fighter_progression = require("progression/fighter_progression")

local fighter_info = require("content/fighter_info")
local gameplay_data = require("resources/gameplay_data")

require("engine/debug/logging")

describe('fighter_progression', function ()

  describe('_init', function ()

    it('should init a fighter_progression for an npc', function ()
      local mock_fighter_info = fighter_info(4, 4, 2, 5, {11, 27}, {12, 28})
      local f_progression = fighter_progression(character_types.npc, mock_fighter_info)
      assert.are_same({
          character_types.npc,
          control_types.ai,
          2,
          5,
          {11, 27},
          {12, 28},
          {},
          {},
          {}
        },
        {
          f_progression.character_type,
          f_progression.control_type,
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

    it('should init a fighter_progression with pc_info for a pc', function ()
      local mock_fighter_info = fighter_info(0, 0, 2, 5, {11, 27}, {12, 28})
      local f_progression = fighter_progression(character_types.pc, mock_fighter_info)
      assert.are_same({
          character_types.pc,
          control_types.human,
          2,
          5,
          {11, 27},
          {12, 28},
          {},
          {},
          {}
        },
        {
          f_progression.character_type,
          f_progression.control_type,
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

    local mock_pc_fighter_info = fighter_info(0, 0, 1, 3, {}, {})
    local mock_fighter_info = fighter_info(4, 4, 2, 5, {11, 27}, {12, 28})

    local pc_f_progression
    local f_progression

    before_each(function ()
      pc_f_progression = fighter_progression(character_types.pc, mock_pc_fighter_info)
      f_progression = fighter_progression(character_types.npc, mock_fighter_info)
    end)

    describe('get_name', function ()

      it('should return the name from the character info', function ()
        -- this test depends on gameplay_data
        assert.are_equal("you", pc_f_progression:get_name())
      end)

      it('should return the name from the character info', function ()
        -- this test depends on gameplay_data
        assert.are_equal("manager", f_progression:get_name())
      end)

    end)

    describe('(spying add_received_quote_id_count_map)', function ()

      setup(function ()
        stub(fighter_progression, "add_received_quote_id_count_map")
        stub(fighter_progression, "check_learn_quote")
      end)

      teardown(function ()
        fighter_progression.add_received_quote_id_count_map:revert()
        fighter_progression.check_learn_quote:revert()
      end)

      after_each(function ()
        fighter_progression.add_received_quote_id_count_map:clear()
        fighter_progression.check_learn_quote:clear()
      end)

      describe('transfer_received_attack_id_count_map', function ()

        it('should call add_received_quote_id_count_map with self.received_attack_id_count_persistent_map and passed map', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_attack_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.add_received_quote_id_count_map)
          s.was_called(1)
          s.was_called_with(match.ref(f_progression.received_attack_id_count_persistent_map), match.ref(added_count_map))
        end)

        it('should call check_learn_quote with the added_count_map (before clearing) and quote_types.attack', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_attack_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.check_learn_quote)
          s.was_called(1)
          -- exceptionally check the table content by value, not ref, to make sure we haven't cleared it too early
          -- do not pass added_count_map itself, though, as it is now empty so it would be like passing {}!
          s.was_called_with(match.ref(f_progression), {[1] = 2}, quote_types.attack)
        end)

        it('should clear the added_count_map', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_attack_id_count_map(added_count_map)

          assert.are_same({}, added_count_map)
        end)

      end)

      describe('transfer_received_reply_id_count_map', function ()

        it('should call add_received_quote_id_count_map with self.received_reply_id_count_persistent_map and passed map', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_reply_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.add_received_quote_id_count_map)
          s.was_called(1)
          s.was_called_with(match.ref(f_progression.received_reply_id_count_persistent_map), match.ref(added_count_map))

          local s = assert.spy(fighter_progression.check_learn_quote)
          s.was_called(1)
          s.was_called_with(match.ref(f_progression), match.ref(added_count_map), quote_types.reply)
        end)

        it('should call check_learn_quote with the added_count_map (before clearing) and quote_types.reply', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_reply_id_count_map(added_count_map)

          local s = assert.spy(fighter_progression.check_learn_quote)
          s.was_called(1)
          -- exceptionally check the table content by value, not ref, to make sure we haven't cleared it too early
          -- do not pass added_count_map itself, though, as it is now empty so it would be like passing {}!
          s.was_called_with(match.ref(f_progression), {[1] = 2}, quote_types.reply)
        end)

        it('should clear the added_count_map', function ()
          local added_count_map = {[1] = 2}

          f_progression:transfer_received_reply_id_count_map(added_count_map)

          assert.are_same({}, added_count_map)
        end)

      end)

    end)

    describe('check_learn_quote', function ()

      -- ! these tests depend on gameplay_data and may break during rebalancing !

      it('should not learn any quote staying below the required count threshold (attack of same level)', function ()
        -- quote 8 is of level 2, mock fighter has level 2
        -- so the threshold is exactly the base threshold
        -- which is gameplay_data.base_learning_repetition_threshold = 2
        -- (we hardcode counts for readability)
        local added_count_map = {[8] = 1}
        -- required to simulate the previous action of add_received_quote_id_count_map
        -- and avoid nil value
        f_progression.received_attack_id_count_persistent_map = {[8] = 1}

        f_progression:check_learn_quote(added_count_map, quote_types.attack)

        -- we learn nothing, but keep the initial known attack ids 11, 27
        assert.are_same({11, 27}, f_progression.known_attack_ids)
      end)

      it('should learn a quote just reaching the required count threshold (attack of same level)', function ()
        -- quote 8 is of level 2, mock fighter has level 2
        local added_count_map = {[8] = 1}  -- increase doesn't matter, only new count below does
        f_progression.received_attack_id_count_persistent_map = {[8] = 2}

        f_progression:check_learn_quote(added_count_map, quote_types.attack)

        assert.are_same({11, 27, 8}, f_progression.known_attack_ids)
      end)

      it('should learn a quote just reaching the required count threshold (reply of same level)', function ()
        -- quote 7 is of level 2, mock fighter has level 2
        local added_count_map = {[8] = 1}  -- increase doesn't matter, only new count below does
        f_progression.received_reply_id_count_persistent_map = {[8] = 2}

        f_progression:check_learn_quote(added_count_map, quote_types.reply)

        assert.are_same({12, 28, 8}, f_progression.known_reply_ids)
      end)

      it('should learn a quote going above the required count threshold (attack of same level)', function ()
        -- quote 7 is of level 2, mock fighter has level 2
        local added_count_map = {[8] = 2}  -- increase doesn't matter, only new count below does
        f_progression.received_attack_id_count_persistent_map = {[8] = 3}

        f_progression:check_learn_quote(added_count_map, quote_types.attack)

        assert.are_same({11, 27, 8}, f_progression.known_attack_ids)
      end)

      it('should learn a quote just reaching the required count threshold (attack of lower level)', function ()
        -- quote 1 is of level 1, mock fighter has level 2, so only 1 reception is needed
        local added_count_map = {[1] = 1}  -- increase doesn't matter, only new count below does
        f_progression.received_attack_id_count_persistent_map = {[1] = 1}

        f_progression:check_learn_quote(added_count_map, quote_types.attack)

        assert.are_same({11, 27, 1}, f_progression.known_attack_ids)
      end)

      it('should learn a quote going above the required count threshold (attack of lower level)', function ()
        -- quote 1 is of level 1, mock fighter has level 2, so only 1 reception is needed
        local added_count_map = {[1] = 1}  -- increase doesn't matter, only new count below does
        f_progression.received_attack_id_count_persistent_map = {[1] = 2}

        f_progression:check_learn_quote(added_count_map, quote_types.attack)

        assert.are_same({11, 27, 1}, f_progression.known_attack_ids)
      end)

    end)

    describe('try_learn_quote_match', function ()

      it('(with npc) should do nothing (even with id <= 0)', function ()
        f_progression.known_quote_match_ids = {1, 2, 3}

        f_progression:try_learn_quote_match(0)

        assert.are_same({1, 2, 3}, f_progression.known_quote_match_ids)
      end)

      it('(with pc) should error if id <= 0 (like cancel quote)', function ()
        assert.has_error(function ()
          pc_f_progression:try_learn_quote_match(0)
        end)
      end)

      it('(with pc) should add quote id if not already known', function ()
        pc_f_progression.known_quote_match_ids = {1, 2, 3}

        pc_f_progression:try_learn_quote_match(4)

        assert.are_same({1, 2, 3, 4}, pc_f_progression.known_quote_match_ids)
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
