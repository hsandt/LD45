local gamestate = require("engine/application/gamestate")

local adventure = derived_class(gamestate)

adventure.type = ':adventure'

function adventure:_init(app)
  gamestate._init(self, app)
end

function adventure:on_enter()
end

function adventure:on_exit()
end

function adventure:update()
end

function adventure:render()
end

return adventure
