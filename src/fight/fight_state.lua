local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")

local painter = require("render/painter")
local visual_data = require("resources/visual_data")
local audio_data = require("resources/audio_data")

local fight_state = new_class(gamestate)

fight_state.type = ':fight'

function fight_state:_init()
  gamestate._init(self)
end

function fight_state:on_enter()
  self.app.managers[':dialogue'].should_show_bottom_box = true

  self.app.managers[':fight'].active = true
  self.app.managers[':fight']:start_fight_with_next_opponent()
end

function fight_state:on_exit()
  self.app.managers[':dialogue'].should_show_bottom_box = false

  self.app.managers[':fight'].active = false
end

function fight_state:update()
end

function fight_state:render()
  painter.draw_background(self.app.game_session.floor_number)
  painter.draw_floor_number(self.app.game_session.floor_number)
end

return fight_state
