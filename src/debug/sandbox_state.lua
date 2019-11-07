local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
require("engine/core/class")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local visual_data = require("resources/visual_data")

-- sandbox: gamestate to test simple stuff actually running in PICO-8
local sandbox_state = derived_class(gamestate)

sandbox_state.type = ':sandbox'

function sandbox_state:_init()
  gamestate._init(self)

  self.hit_fx = animated_sprite(visual_data.anim_sprites.hit_fx)
end

function sandbox_state:on_enter()
  self.hit_fx:play('once')
end

function sandbox_state:on_exit()
end

function sandbox_state:update()
  self.hit_fx:update()

  if input:is_just_pressed(button_ids.x) then
    self:go_back()
  end
end

function sandbox_state:render()
  self.hit_fx:render(vector(64, 64))
end

function sandbox_state:go_back()
  flow:query_gamestate_type(':main_menu')
end

return sandbox_state
