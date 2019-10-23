require("engine/core/class")

local manager = require("engine/application/manager")

local adventure_manager = derived_class(manager)

adventure_manager.type = ':adventure'
adventure_manager.initially_active = false

--[[
Dynamic parameters (fixed for a given adventure segment, i.e. until adventure state is exited)
  next_step     string           name of the current adventure step ("intro", "floor loop", etc.)

State
--]]
function adventure_manager:_init()
  manager._init(self)

  self.next_step = ""
end

function adventure_manager:start()  -- override
end

function adventure_manager:update()  -- override
end

function adventure_manager:render()  -- override
end

return adventure_manager
