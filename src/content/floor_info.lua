local floor_info = new_struct()

function floor_info:_init(number, npc_level_min, npc_level_max)
  self.number = number
  self.npc_level_min = npc_level_min
  self.npc_level_max = npc_level_max
end

--#if log
function floor_info:_tostring()
  return "floor_info("..joinstr(", ", self.number, self.npc_level_min, self.npc_level_max)..")"
end
--#endif

return floor_info
