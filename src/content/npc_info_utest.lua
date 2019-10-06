require("engine/test/bustedhelper")
local npc_info = require("content/npc_info")

describe('npc_info', function ()

  describe('_init', function ()
    it('should init a npc_info with id, name, level, initial quote ids', function ()
      local n = npc_info(8, "employee", 4, {11, 27})
      assert.are_same({8, "employee", 4, {11, 27}}, {n.id, n.name, n.level, n.initial_quote_ids})
    end)
  end)

  describe('_tostring', function ()
    it('npc_info(8, "employee", 4, {11, 27}) => "npc_info(8, "employee", 4, {11, 27})"', function ()
      local n = npc_info(8, "employee", 4, {11, 27})
      assert.are_equal("npc_info(8, \"employee\", 4, {11, 27})", n:_tostring())
    end)
  end)

end)
