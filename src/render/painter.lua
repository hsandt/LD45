require("engine/core/math")
local ui = require("engine/ui/ui")

local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

local painter = {}

function painter.draw_background(floor_number)
  if floor_number < #gameplay_data.floors then
    painter.draw_background_stairs()
  else
    painter.draw_background_ceo_room()
  end
end

function painter.draw_background_stairs()
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
  visual_data.sprites.lower_stairs_step:render(vector(104, 80))
  visual_data.sprites.lower_stairs_step:render(vector(110, 84))
end

function painter.draw_background_ceo_room()
  -- wall (ok to draw bottom part without clamping because floor s drawn afterward,
  --   and will hide the extra part at the bottom)
  for i = 0, 11 do
    for j = 0, 4 do
      visual_data.sprites.ceo_room_wallpaper:render(vector(11 * i, 11 * j - 1))
    end
  end

  -- floor
  line(0, 50, 127, 50, colors.black)
  rectfill(0, 51, 127, 127, colors.indigo)

  -- desk
  rect(103, 56, 120, 96, colors.black)
  line(104, 85, 119, 85, colors.black)
  rectfill(104, 57, 119, 84, colors.orange)
  rectfill(104, 86, 119, 95, colors.brown)
end

function painter.draw_floor_number(floor_number)
  ui.draw_box(110, 65, 124, 73, colors.black, colors.orange)
  ui.print_centered(floor_number.."f", 117, 69, colors.black)
end

return painter
