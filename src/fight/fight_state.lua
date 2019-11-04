local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")

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

  self.app.managers[':dialogue'].should_show_bottom_box = true
end

function fight_state:on_exit()
  self.app.managers[':fight'].active = false

  self.app.managers[':dialogue'].should_show_bottom_box = false
end

function fight_state:update()
end

function fight_state:render()
  painter.draw_background(self.app.game_session.floor_number)
  self:draw_floor_number()
end

function fight_state:draw_floor_number()
  ui.draw_box(110, 65, 124, 73, colors.black, colors.orange)
  ui.print_centered(self.app.game_session.floor_number.."f", 117, 69, colors.black)
end

return fight_state
