require("engine/core/class")
require("engine/core/math")
local ui = require("engine/ui/ui")

local visual_data = require("resources/visual_data")

local fighter = new_class()

-- max_hp: int                initial hp
-- sprite: sprite_data        sprite to render
-- pos: vector                position on screen
-- direction: horizontal_dirs facing left or right?
function fighter:_init(max_hp, sprite, pos, direction)
  self.hp = max_hp
  self.sprite = sprite
  self.pos = pos
  self.direction = direction
end

--#if log
function fighter:_tostring()
  return "fighter("..joinstr(", ", self.hp, self.sprite, self.pos, self.direction)..")"
end
--#endif

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
