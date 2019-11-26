require("engine/test/bustedhelper")
local game_session = require("progression/game_session")

local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")

describe('game_session', function ()

  -- no need to have actual fighter_progression instances
  local fake_npc_fighter_prog1 = {level = 1}
  local fake_npc_fighter_prog2 = {level = 2}
  local fake_npc_fighter_prog3 = {level = 3}

  describe('_init', function ()

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
      assert.are_same({gameplay_data.initial_floor, 0, {}}, {gs.floor_number, gs.fight_count, gs.met_npc_ids})
      assert.are_same(fighter_progression(character_types.pc, gameplay_data.pc_fighter_info), gs.pc_fighter_progression)
      assert.are_equal(fake_npc_fighter_prog1, gs.npc_fighter_progressions[1])
      assert.are_equal(fake_npc_fighter_prog2, gs.npc_fighter_progressions[2])
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
      gs.met_npc_ids = {[1] = true, [5] = true}
      assert.is_true(gs:has_met_npc(5))
    end)

    it('should return true if npc was met', function ()
      local gs = game_session()
      gs.met_npc_ids = {[1] = true, [5] = true}
      assert.is_false(gs:has_met_npc(4))
    end)

  end)

  describe('register_met_npc', function ()

    it('should add npc id to set of met npc ids', function ()
      local gs = game_session()
      gs:register_met_npc(5)
      assert.is_true(gs.met_npc_ids[5])
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

  describe('generate_npc_fighter_progressions', function ()
    it('should return some npcs, one per archetype', function ()
      local npc_fighter_progs = game_session.generate_npc_fighter_progressions()

      -- Relies on generate_npc_fighter_progressions working.
      assert.is_true(#npc_fighter_progs > 1)
      assert.are_equal(1, npc_fighter_progs[1].fighter_info.id)
    end)
  end)

end)
