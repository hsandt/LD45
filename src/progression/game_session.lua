require("engine/core/class")

local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")

local game_session = new_class()

function game_session:_init()
  -- current floor number the player character is located at
  self.floor_number = 1

  self.pc_fighter_progression = fighter_progression(character_types.human, gameplay_data.pc_fighter_info)
  self.npc_fighter_progressions = game_session.generate_npc_fighter_progressions()
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
    add(npc_fighter_progressions, fighter_progression(character_types.ai, npc_fighter_info))
  end

  return npc_fighter_progressions
end

return game_session
