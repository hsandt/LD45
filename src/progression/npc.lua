require("engine/core/class")
require("engine/core/helper")

local npc = new_class()

function npc:_init(some_npc_info)
  -- parameters
  self.info = some_npc_info

  -- state
  self.known_quote_ids = copy_seq(some_npc_info.initial_quote_ids)
end

return npc
