local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")

local painter = require("render/painter")
local visual_data = require("resources/visual_data")
local audio_data = require("resources/audio_data")

local fight_state = derived_class(gamestate)

fight_state.type = ':fight'

function fight_state:_init()
  gamestate._init(self)
end

function fight_state:on_enter()
  local fm = self.app.managers[':fight']

  self.app.managers[':dialogue'].should_show_bottom_box = true

  fm.active = true
  fm:start_fight_with_next_opponent()
end

function fight_state:on_exit()
  self.app.managers[':dialogue'].should_show_bottom_box = false

  self.app.managers[':fight'].active = false
end

function fight_state:update()
end

function fight_state:render()
  local fm = self.app.managers[':fight']
  local floor_number = self.app.game_session.floor_number

  painter.draw_background(floor_number)
  painter.draw_floor_number(floor_number)

  -- same as adventure_state:render, we prefer drawing characters here
  --   than in fight_manager:render because of guaranteed layering
  fm:draw_fighters()
end

return fight_state
