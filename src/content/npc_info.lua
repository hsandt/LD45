local npc_info = new_struct()

function npc_info:_init(id, name, level)
  self.id = id
  self.name = name
  self.level = level
end

--#if log
function npc_info:_tostring()
  return "npc_info("..joinstr(", ", self.id, dump(self.name), self.level)..")"
end
--#endif

return npc_info
