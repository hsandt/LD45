local gamestate = require("engine/application/gamestate")

local painter = require("render/painter")
local visual_data = require("resources/visual_data")

local fight_state = derived_class(gamestate)

fight_state.type = ':fight'

function fight_state:_init(app)
  gamestate._init(self, app)
end

function fight_state:on_enter()
  self.app.managers[':fight'].active = true
  self.app.managers[':fight']:start_fight_with_next_opponent()
  -- self.app:start_coroutine(self.play_intro, self)
end

function fight_state:on_exit()
  self.app.managers[':fight'].active = false
end

function fight_state:update()
end

function fight_state:render()
  painter.draw_background()
end

function fight_state:play_intro()
  local dm = self.app.managers[':fight']
  local pc_speaker = self.pc.speaker

end

return fight_state
