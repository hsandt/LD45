require("engine/core/class")
require("engine/core/math")
local ui = require("engine/ui/ui")

local visual_data = require("resources/visual_data")

control_types = enum {
  'human',
  'ai'
}

local fighter = new_class()

--[[
Parameters
  control_type: control_types   is the fighter controlled by the player or some ai?
  max_hp: int                   initial hp
  sprite: sprite_data           sprite to render
  pos: vector                   position on screen
  direction: horizontal_dirs    facing left or right?

State
  hp: int                       current hp
  is_attacker: bool             true iff fighter attacks this turn
  last_quote: (quote_info|nil)  last quote said, if any
--]]
function fighter:_init(control_type, max_hp, sprite, pos, direction)
  self.control_type = control_type
  self.sprite = sprite
  self.pos = pos
  self.direction = direction

  self.hp = max_hp
  self.is_attacker = false
  self.last_quote = nil
end

--#if log
function fighter:_tostring()
  return "fighter("..joinstr(", ", self.control_type, self.hp, self.sprite, self.pos, self.direction)..")"
end
--#endif

-- logic

function fighter:auto_pick_quote()
  assert(self.control_type == control_types.ai)
  -- todo
end

function fighter:take_damage(damage)
  self.hp = self.hp - damage
  if self.hp <= 0 then
    self.hp = 0
  end
end

function fighter:is_alive()
  return self.hp > 0
end

-- render

function fighter:draw()
  self.sprite:render(self.pos)
  self:draw_health_bar()
end

function fighter:draw_health_bar()
  local center_x_offset = visual_data.health_bar_center_x_dist_from_char

  -- health bar is behind character
  if self.direction == horizontal_dirs.right  then
    center_x_offset = - center_x_offset
  end

  local center_x = self.pos.x + center_x_offset
  local left = center_x - visual_data.health_bar_half_width
  local right = center_x + visual_data.health_bar_half_width
  local top = self.pos.y + visual_data.health_bar_top_from_char
  local bottom = self.pos.y + visual_data.health_bar_bottom_from_char
  ui.draw_box(left, top, right, bottom, colors.dark_blue, colors.blue)
end

return fighter
