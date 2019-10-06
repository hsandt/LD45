-- connects an attack with a reply, stating that the reply works against the attack
local quote_match_info = new_struct()

function quote_match_info:_init(attack_id, reply_id)
  self.attack_id = attack_id
  self.reply_id = reply_id
end

--#if log
function quote_match_info:_tostring()
  return "quote_match_info("..joinstr(", ", self.attack_id, self.reply_id)..")"
end
--#endif

return quote_match_info
