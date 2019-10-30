require("engine/core/class")

-- connects an attack with a reply, stating that the reply works against the attack
local quote_match_info = new_struct()

-- id: int
-- attack_id: int
-- reply_id: int
-- power: int
function quote_match_info:_init(id, attack_id, reply_id, power)
  self.id = id
  self.attack_id = attack_id
  self.reply_id = reply_id
  self.power = power
end

--#if log
function quote_match_info:_tostring()
  return "quote_match_info("..joinstr(", ", self.id, self.attack_id, self.reply_id, self.power)..")"
end
--#endif

return quote_match_info
