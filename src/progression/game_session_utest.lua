require("engine/test/bustedhelper")
local game_session = require("progression/game_session")

describe('game_session', function ()

  describe('_init', function ()

    -- no need to have actual npc instances
    local fake_npc1 = {}
    local fake_npc2 = {}

    setup(function ()
      stub(game_session, "generate_npcs", function ()
        return {fake_npc1, fake_npc2}
      end)
    end)

    teardown(function ()
      game_session.generate_npcs:revert()
    end)

    it('should init a game_session', function ()
      local s = game_session()
      assert.are_same({1, {}}, {s.floor_number, s.pc_known_quotes})
      assert.are_equal(fake_npc1, s.npcs[1])
      assert.are_equal(fake_npc2, s.npcs[2])
    end)
  end)

  describe('generate_npcs', function ()
    it('should return 20 npcs, one per archetype', function ()
      local npcs = game_session.generate_npcs()
      assert.are_equal(20, #npcs)
      assert.are_same({1, 20}, {npcs[1].info.id, npcs[20].info.id})
    end)
  end)

end)
