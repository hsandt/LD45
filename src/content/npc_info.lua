require("engine/core/class")

local npc_info = new_struct()

-- id: int
-- name: string
-- level: int
-- initial_quote_ids: {int}
function npc_info:_init(id, name, level, initial_quote_ids)
  self.id = id
  self.name = name
  self.level = level
  self.initial_quote_ids = initial_quote_ids
end

--#if log
function npc_info:_tostring()
  return "npc_info("..joinstr(", ", self.id, dump(self.name), self.level, dump_sequence(self.initial_quote_ids))..")"
end
--#endif

return npc_info
