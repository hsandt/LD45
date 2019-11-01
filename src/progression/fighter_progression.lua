require("engine/core/class")
require("engine/core/helper")

local gameplay_data = require("resources/gameplay_data")

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
  character_info: character_info      cached reference to character info (derived from fighter_info)

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

--#if log
function fighter_progression:get_name()
  local character_info

  if self.character_type == character_types.human then
    character_info = gameplay_data.pc_info
  else
    character_info = gameplay_data.npc_info_s[self.fighter_info.character_info_id]
    assert(character_info, "no character_info found for id: "..self.fighter_info.character_info_id)
  end

  return character_info.name
end
--#endif

function fighter_progression:transfer_received_attack_id_count_map(added_count_map)
  fighter_progression.add_received_quote_id_count_map(self.received_attack_id_count_persistent_map, added_count_map)
  self:check_learn_quote(added_count_map, quote_types.attack)
  clear_table(added_count_map)
end

function fighter_progression:transfer_received_reply_id_count_map(added_count_map)
  fighter_progression.add_received_quote_id_count_map(self.received_reply_id_count_persistent_map, added_count_map)
  self:check_learn_quote(added_count_map, quote_types.reply)
  clear_table(added_count_map)
end

-- static (generic enough to be a table helper)
function fighter_progression.add_received_quote_id_count_map(modified_count_map, added_count_map)
  for quote_id, counter in pairs(added_count_map) do
    -- sum counts (uninitialised count defaults to 0)
    local reception_count = modified_count_map[quote_id] or 0
    reception_count = reception_count + counter
    modified_count_map[quote_id] = reception_count
  end
end

function fighter_progression:check_learn_quote(added_count_map, quote_type)
  local known_quote_ids
  local received_quote_id_count_map
  if quote_type == quote_types.attack then
    known_quote_ids = self.known_attack_ids
    received_quote_id_count_map = self.received_attack_id_count_persistent_map
  else  -- quote_type == quote_types.reply
    known_quote_ids = self.known_reply_ids
    received_quote_id_count_map = self.received_reply_id_count_persistent_map
  end

  for quote_id, _ in pairs(added_count_map) do
    local received_quote = gameplay_data:get_quote(quote_type, quote_id)
    local learning_difficulty = received_quote.level - self.level
    local learning_repetition_threshold = gameplay_data.base_learning_repetition_threshold + learning_difficulty

    -- Check if we've received the quote enough times to learn it.
    -- Note that for quotes at very low level compared to the fighter, the threshold is negative,
    --   but we don't need to check if reception_count >= 1 since the added_count_map only
    --   contains counts of at least 1.
    -- The first members should not be nil as long as add_received_quote_id_count_map
    --   added the counters properly.
    if received_quote_id_count_map[quote_id] >= learning_repetition_threshold then
      add(known_quote_ids, quote_id)
--#if log
      local quote_type_name = quote_type == quote_types.attack and "attack" or "reply"
      log("fighter '"..self:get_name().."' learns "..quote_type_name.." quote "..quote_id..": \""..
        gameplay_data:get_quote(quote_type, quote_id).text.."\"", "itest")
--#endif
    end
  end
end

function fighter_progression:try_learn_quote_match(id)
  assert(id > 0, "cannot learn cancel quote match")

  if not contains(self.known_quote_match_ids, id) then
    add(self.known_quote_match_ids, id)
--#if log
    log("fighter '"..self:get_name().."' learns "..gameplay_data.quote_matches[id], "itest")
--#endif
  end
end

return fighter_progression
