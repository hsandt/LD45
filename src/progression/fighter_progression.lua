require("engine/core/class")
require("engine/core/helper")

character_types = enum {
  'human',
  'ai'
}

-- class holding persistent information on the fighter, pc or npc

local fighter_progression = new_class()

-- character_type: character_types    is the fighter controlled by the player or some ai?
-- fighter_info: fighter_info         fighter info this was created with
-- level: int                         current level (only useful for npc)
-- known_attack_ids: {int}            known attack ids
-- known_reply_ids: {int}             known reply ids
-- known_quote_match_ids: {int}       known quote matches (only useful for npc)
function fighter_progression:_init(character_type, some_fighter_info)
  -- parameters
  self.character_type = character_type
  self.fighter_info = some_fighter_info

  -- state
  self.level = some_fighter_info.initial_level
  self.max_hp = some_fighter_info.initial_max_hp
  self.known_attack_ids = copy_seq(some_fighter_info.initial_attack_ids)
  self.known_reply_ids = copy_seq(some_fighter_info.initial_reply_ids)
  self.known_quote_match_ids = copy_seq(some_fighter_info.initial_quote_match_ids)
end

return fighter_progression