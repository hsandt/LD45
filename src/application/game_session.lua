require("engine/core/class")

local game_session = new_class()

function game_session:_init()
  -- "start with nothing"
  self.pc_known_quotes = {}
end

return game_session
