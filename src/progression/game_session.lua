require("engine/core/class")

local gameplay_data = require("resources/gameplay_data")
local npc = require("progression/npc")

local game_session = new_class()

function game_session:_init()
  self.floor_number = 1

  -- "start with nothing"
  self.pc_known_quotes = {}

  self.npcs = game_session.generate_npcs()
end

function game_session.generate_npcs()
  local npcs = {}

  -- generate one instance of npc per archetype
  for some_npc_info in all(gameplay_data.npc_info_s) do
    add(npcs, npc(some_npc_info))
  end

  return npcs
end

return game_session
