require("engine/core/class")
require("engine/core/helper")

local fighter_info = new_struct()

-- id: int
-- character_info_id: int
-- initial_level: int
-- initial_max_hp: int
-- initial_attack_ids: {int}
-- initial_reply_ids: {int}
-- initial_quote_match_ids: {int}
function fighter_info:_init(id, character_info_id, initial_level, initial_max_hp, initial_attack_ids, initial_reply_ids, initial_quote_match_ids)
  self.id = id
  self.character_info_id = character_info_id
  self.initial_level = initial_level
  self.initial_max_hp = initial_max_hp
  self.initial_attack_ids = initial_attack_ids
  self.initial_reply_ids = initial_reply_ids
  self.initial_quote_match_ids = initial_quote_match_ids
end

--#if log
function fighter_info:_tostring()
  return "[fighter_info("..joinstr(", ", self.id, self.character_info_id)..")]"
end
--#endif

return fighter_info
