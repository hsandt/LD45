local gamestate = require("engine/application/gamestate")

local painter = require("render/painter")
local visual_data = require("resources/visual_data")

local fight_state = derived_class(gamestate)

fight_state.type = ':fight'

function fight_state:_init()
  gamestate._init(self)
end

function fight_state:on_enter()
  self.app.managers[':fight'].active = true
  self.app.managers[':fight']:start_fight_with_next_opponent()
end

function fight_state:on_exit()
  self.app.managers[':fight'].active = false
end

function fight_state:update()
end

function fight_state:render()
  painter.draw_background()
end

return fight_state
