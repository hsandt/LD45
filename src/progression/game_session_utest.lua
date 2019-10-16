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
      assert.are_equal(1, gs.floor_number)
      assert.are_same(fighter_progression(character_types.human, gameplay_data.pc_fighter_info), gs.pc_fighter_progression)
      assert.are_equal(fake_npc_fighter_prog1, gs.npc_fighter_progressions[1])
      assert.are_equal(fake_npc_fighter_prog2, gs.npc_fighter_progressions[2])
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
    it('should return 20 npcs, one per archetype', function ()
      local npc_fighter_progs = game_session.generate_npc_fighter_progressions()

      -- Relies on generate_npc_fighter_progressions working.
      assert.are_equal(20, #npc_fighter_progs)
      assert.are_same({1, 20}, {npc_fighter_progs[1].fighter_info.id, npc_fighter_progs[20].fighter_info.id})
    end)
  end)

end)
