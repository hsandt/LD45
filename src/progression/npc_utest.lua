require("engine/test/bustedhelper")
local npc = require("progression/npc")

local npc_info = require("content/npc_info")

describe('npc', function ()

  describe('_init', function ()
    it('should init a npc with empty pc_known_quotes', function ()
      local i = npc_info(8, "employee", 4, {11, 27})
      local n = npc(i)
      assert.are_equal(i, n.info)
      assert.are_same({{11, 27}}, {n.known_quote_ids})
    end)
  end)

end)
