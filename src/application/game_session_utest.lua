require("engine/test/bustedhelper")
local game_session = require("application/game_session")

describe('game_session', function ()

  describe('_init', function ()
    it('should init a game_session with empty pc_known_quotes', function ()
      local s = game_session()
      assert.are_same({{}}, {s.pc_known_quotes})
    end)
  end)

end)
