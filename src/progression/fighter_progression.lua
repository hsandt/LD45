require("engine/core/class")
require("engine/core/helper")

character_types = enum {
  'human',
  'ai'
}

-- class holding persistent information on the fighter, pc or npc

local fighter_progression = new_class()

--[[
Parameters
  character_type: character_types     is the fighter controlled by the player or some ai?
  fighter_info: fighter_info          fighter info this was created with

State
  level: int                          current level (only useful for npc)
  known_attack_ids: {int}             known attack ids
  known_reply_ids: {int}              known reply ids
  known_quote_match_ids: {int}        known quote matches (only useful for npc)
  received_attack_id_count_persistent_map: {int: int}
                                      count of new attacks received over past fights,
                                      indexed by attack id (as in fighter, but persistent)
  received_reply_id_count_persistent_map: {int: int}
                                      count of new replies received over past fights,
                                      indexed by reply id (as in fighter, but persistent)
--]]
function fighter_progression:_init(character_type, some_fighter_info)
  -- Parameters
  self.character_type = character_type
  self.fighter_info = some_fighter_info

  -- State
  self.level = some_fighter_info.initial_level
  self.max_hp = some_fighter_info.initial_max_hp
  self.known_attack_ids = copy_seq(some_fighter_info.initial_attack_ids)
  self.known_reply_ids = copy_seq(some_fighter_info.initial_reply_ids)
  self.known_quote_match_ids = copy_seq(some_fighter_info.initial_quote_match_ids)

  self.received_attack_id_count_persistent_map = {}
  self.received_reply_id_count_persistent_map = {}
end

function fighter_progression:add_received_attack_id_count_map(added_count_map)
  fighter_progression.add_received_quote_id_count_map(self.received_attack_id_count_persistent_map, added_count_map)
end

function fighter_progression:add_received_reply_id_count_map(added_count_map)
  fighter_progression.add_received_quote_id_count_map(self.received_reply_id_count_persistent_map, added_count_map)
end

-- static (generic enough to be a table helper)
function fighter_progression.add_received_quote_id_count_map(modified_count_map, added_count_map)
  for quote_id, counter in pairs(added_count_map) do
    local reception_count = modified_count_map[quote_id]
    if reception_count then
      modified_count_map[quote_id] = reception_count + counter
    else
      modified_count_map[quote_id] = counter
    end
  end
end

return fighter_progression
