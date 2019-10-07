local gamestate = require("engine/application/gamestate")

local painter = require("render/painter")

local adventure = derived_class(gamestate)

adventure.type = ':adventure'

function adventure:_init(app)
  gamestate._init(self, app)
end

function adventure:on_enter()
  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  self.app.managers[':dialogue'].should_show_bottom_box = true
end

function adventure:on_exit()
  self.app.managers[':dialogue'].should_show_bottom_box = false
end

function adventure:update()
end

function adventure:render()
  painter.draw_background()
end

return adventure
