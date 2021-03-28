local audio_data = require("resources/audio_data")

local fighter_info = new_struct()

-- id: int
-- character_info_id: int
-- initial_level: int
-- initial_max_hp: int
-- initial_attack_ids: {int}
-- initial_reply_ids: {int}
-- fight_bgm: int (bgm id, defaults to audio_data.bgm.fight_normal)
function fighter_info:init(id, character_info_id, initial_level, initial_max_hp, initial_attack_ids, initial_reply_ids, fight_bgm)
  self.id = id
  self.character_info_id = character_info_id
  self.initial_level = initial_level
  self.initial_max_hp = initial_max_hp
  self.initial_attack_ids = initial_attack_ids
  self.initial_reply_ids = initial_reply_ids
  self.fight_bgm = fight_bgm or audio_data.bgm.fight_normal
end

--#if log
function fighter_info:_tostring()
  return "[fighter_info("..joinstr(", ", self.id, self.character_info_id)..")]"
end
--#endif

return fighter_info
