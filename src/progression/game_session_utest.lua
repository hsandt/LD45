require("test/bustedhelper_game")
local game_session = require("progression/game_session")

local floor_info = require("content/floor_info")
local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")

describe('game_session', function ()

  -- no need to have actual fighter_progression instances
  local fake_npc_fighter_prog1 = {level = 1}
  local fake_npc_fighter_prog2 = {level = 2}
  local fake_npc_fighter_prog3 = {level = 3}

  describe('init', function ()

    setup(function ()
      stub(game_session, "generate_npc_fighter_progressions", function ()
        return {fake_npc_fighter_prog1, fake_npc_fighter_prog2}
      end)
    end)

    teardown(function ()
      game_session.generate_npc_fighter_progressions:revert()
    end)

    it('should init a game_session', function ()
      local gs = game_session()
      assert.are_same({gameplay_data.initial_floor, 0, {}, {}}, {gs.floor_number, gs.fight_count, gs.met_npc_fighter_ids, gs.beaten_npc_fighter_ids})
      assert.are_same(fighter_progression(character_types.pc, gameplay_data.pc_fighter_info), gs.pc_fighter_progression)
      assert.are_equal(fake_npc_fighter_prog1, gs.npc_fighter_progressions[1])
      assert.are_equal(fake_npc_fighter_prog2, gs.npc_fighter_progressions[2])
    end)
  end)

  describe('go_to_floor', function ()

    it('should set the floor number (must unlock floor first not to assert)', function ()
      local gs = game_session()
      gs.floor_number = 1
      gs.max_unlocked_floor = 3

      gs:go_to_floor(3)

      assert.are_equal(3, gs.floor_number)
    end)

  end)

  describe('unlock_floor', function ()

    it('should set the floor number', function ()
      local gs = game_session()
      gs.max_unlocked_floor = 1

      gs:unlock_floor(3)

      assert.are_equal(3, gs.max_unlocked_floor)
    end)

    it('should preserve max unlocked floor if not higher', function ()
      local gs = game_session()
      gs.max_unlocked_floor = 3

      gs:unlock_floor(1)

      assert.are_equal(3, gs.max_unlocked_floor)
    end)

  end)

  describe('increment_fight_count', function ()

    it('should increment the fight count', function ()
      local gs = game_session()
      gs.fight_count = 5
      gs:increment_fight_count()
      assert.are_equal(6, gs.fight_count)
    end)

    it('should clamp at 100', function ()
      local gs = game_session()
      gs.fight_count = 100
      gs:increment_fight_count()
      assert.are_equal(100, gs.fight_count)
    end)

  end)

  describe('has_met_npc', function ()

    it('should return true if npc was met', function ()
      local gs = game_session()
      gs.met_npc_fighter_ids = {[1] = true, [5] = true}
      assert.is_true(gs:has_met_npc(5))
    end)

    it('should return true if npc was met', function ()
      local gs = game_session()
      gs.met_npc_fighter_ids = {[1] = true, [5] = true}
      assert.is_false(gs:has_met_npc(4))
    end)

  end)

  describe('register_met_npc', function ()

    it('should add npc id to set of met npc ids', function ()
      local gs = game_session()
      gs:register_met_npc(5)
      assert.is_true(gs.met_npc_fighter_ids[5])
    end)

  end)

  describe('has_beaten_npc', function ()

    it('should return true if npc was beaten', function ()
      local gs = game_session()
      gs.beaten_npc_fighter_ids = {[1] = true, [5] = true}
      assert.is_true(gs:has_beaten_npc(5))
    end)

    it('should return true if npc was beaten', function ()
      local gs = game_session()
      gs.beaten_npc_fighter_ids = {[1] = true, [5] = true}
      assert.is_false(gs:has_beaten_npc(4))
    end)

  end)

  describe('register_beaten_npc', function ()

    it('should add npc id to set of beaten npc ids', function ()
      local gs = game_session()
      gs:register_beaten_npc(5)
      assert.is_true(gs.beaten_npc_fighter_ids[5])
    end)

  end)

  describe('get_all_npc_fighter_progressions_with_level', function ()

    setup(function ()
      stub(game_session, "generate_npc_fighter_progressions", function ()
        return {fake_npc_fighter_prog1, fake_npc_fighter_prog2, fake_npc_fighter_prog3}
      end)
    end)

    teardown(function ()
      game_session.generate_npc_fighter_progressions:revert()
    end)

    it('should return progression of all npc fighters of a given level', function ()
      local gs = game_session()

      local npc_fighter_progs_level3 = gs:get_all_npc_fighter_progressions_with_level(3)

      assert.are_equal(1, #npc_fighter_progs_level3)
      assert.are_equal(fake_npc_fighter_prog3, npc_fighter_progs_level3[1])
    end)

  end)

  describe('get_all_candidate_npc_fighter_prog', function ()

    local fake_npc_fighter_prog_lv1a = {level = 1}
    local fake_npc_fighter_prog_lv1b = {level = 1}
    local fake_npc_fighter_prog_lv2a = {level = 2}
    local fake_npc_fighter_prog_lv2b = {level = 2}
    local fake_npc_fighter_prog_lv3 = {level = 3}

    setup(function ()
      stub(gameplay_data, "get_floor_info", function (self, floor_number)
        -- hypothetical npc levels related to floor number
        return floor_info(floor_number, max(1, floor_number - 1), min(floor_number + 1, 3))
      end)
      stub(game_session, "get_all_npc_fighter_progressions_with_level", function (self, level)
        -- we are going to return different npcs with the same ids, but we don't care about ids in this test anyway
        if level == 1 then
          return {fake_npc_fighter_prog_lv1a, fake_npc_fighter_prog_lv1b}
        elseif level == 2 then
          return {fake_npc_fighter_prog_lv2a, fake_npc_fighter_prog_lv2b}
        elseif level == 3 then
          return {fake_npc_fighter_prog_lv3}
        else
          -- hypothetical level 0 or 4... no candidate (would error)
          return {}
        end
      end)
    end)

    teardown(function ()
      gameplay_data.get_floor_info:revert()
      game_session.get_all_npc_fighter_progressions_with_level:revert()
    end)

    it('should pick a random npc info among the possible npc levels at the current floor', function ()
      local gs = game_session()
      gs.floor_number = 3

      -- we pass floor number of 3, so npc levels should be 2 to 3
      -- we don't go into details but we should have 3 mock npc infos now, spread on 2 levels
      -- we just check that we have 4 of them
      assert.are_equal(3, #gs:get_all_candidate_npc_fighter_prog())
    end)

    it('should pick a random npc info among the possible npc levels at the current floor, excluding the last opponent', function ()
      local gs = game_session()
      gs.last_opponent = fake_npc_fighter_prog_lv1a
      gs.floor_number = 2

      -- we pass floor number of 2, so npc levels should be 1 to 3
      -- we don't go into details but we should have 5 mock npc infos now, spread on 3 levels
      -- however, we have just met one of them, which makes 5 - 1 = 4 left
      assert.are_equal(4, #gs:get_all_candidate_npc_fighter_prog())
    end)

    it('should repick the last opponent if there is really no other candidate', function ()
      local gs = game_session()
      gs.last_opponent = fake_npc_fighter_prog_lv3
      gs.floor_number = 4

      -- we pass floor number of 4, so npc levels should be 3 to 3
      -- problem is, there is only one NPC at that level and we've just fought him
      -- so no choice, we fight him again
      local candidate_npc_fighter_prog_s = gs:get_all_candidate_npc_fighter_prog()
      assert.are_equal(1, #candidate_npc_fighter_prog_s)
      assert.are_equal(fake_npc_fighter_prog_lv3, candidate_npc_fighter_prog_s[1])
    end)

  end)

  describe('generate_npc_fighter_progressions', function ()
    it('should return some npcs, one per archetype', function ()
      local npc_fighter_progs = game_session.generate_npc_fighter_progressions()

      -- Relies on generate_npc_fighter_progressions working.
      assert.is_true(#npc_fighter_progs > 1)
      assert.are_equal(1, npc_fighter_progs[1].fighter_info.id)
    end)
  end)

end)
