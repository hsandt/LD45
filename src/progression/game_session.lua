require("engine/core/class")

local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")

local game_session = new_class()

function game_session:_init()
  -- current floor number the player character is located at
  self.floor_number = gameplay_data.initial_floor
  -- number of fights already finished (used for tutorial steps)
  self.fight_count = 0
  -- set of npc fighter ids (as opposed to character info id, in case they differ)
  --   already met by the player character
  -- format: {[met_npc_fighter_id] = true, ...}
  self.met_npc_fighter_ids = {}

  -- fighter persistent progression statuses
  self.pc_fighter_progression = fighter_progression(character_types.pc, gameplay_data.pc_fighter_info)
  self.npc_fighter_progressions = game_session.generate_npc_fighter_progressions()
end

function game_session:increment_fight_count()
  self.fight_count = min(self.fight_count + 1, 100)
end

function game_session:has_met_npc(npc_fighter_id)
  -- equality test just to return false rather than nil
  return self.met_npc_fighter_ids[npc_fighter_id] == true
end

function game_session:register_met_npc(npc_fighter_id)
  self.met_npc_fighter_ids[npc_fighter_id] = true
end

function game_session:get_all_npc_fighter_progressions_with_level(level)
  return filter(self.npc_fighter_progressions, function (fighter_prog)
    return fighter_prog.level == level
  end)
end

-- static
function game_session.generate_npc_fighter_progressions()
  local npc_fighter_progressions = {}

  -- generate one instance of npc per archetype
  for npc_fighter_info in all(gameplay_data.npc_fighter_info_s) do
    add(npc_fighter_progressions, fighter_progression(character_types.npc, npc_fighter_info))
  end

  return npc_fighter_progressions
end

return game_session
