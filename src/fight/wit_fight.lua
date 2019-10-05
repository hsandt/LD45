local gamestate = require("engine/application/gamestate")
require("engine/core/class")
local ui = require("engine/ui/ui")

local visual_data = require("resources/visual_data")

-- wit fight: in-game gamestate for fighting an opponent
local wit_fight = derived_class(gamestate)

wit_fight.type = ':wit_fight'

function wit_fight:_init()
end

function wit_fight:on_enter()
end

function wit_fight:on_exit()
end

function wit_fight:update()
end

function wit_fight:render()
  self:draw_background()
  self:draw_characters()
  self:draw_hud()
end

function wit_fight:draw_background()
  -- wall
  rectfill(0, 0, 127, 127, colors.dark_gray)

  -- floor
  rectfill(0, 51, 103, 127, colors.light_gray)
  line(0, 50, 104, 50, colors.black)
  line(104, 50, 104, 127, colors.black)

  -- upper stairs
  visual_data.sprites.upper_stairs_step1:render(vector(104, 45))
  local pos = vector(110, 40)
  for i = 1, 3 do
    visual_data.sprites.upper_stairs_step2:render(pos)
    pos = pos + vector(6, -6)
  end
  -- lower stairs
  visual_data.sprites.lower_stairs_step:render(vector(105, 80))
  visual_data.sprites.lower_stairs_step:render(vector(111, 84))
end

function wit_fight:draw_characters()
  visual_data.sprites.player_character:render(vector(19, 78))
  visual_data.sprites.npc1:render(vector(86, 78))
end

function wit_fight:draw_hud()
  wit_fight:draw_bottom_box()
end

function wit_fight:draw_bottom_box()
  ui.draw_rounded_box(0, 89, 127, 127, colors.dark_blue, colors.indigo)
end

return wit_fight
