require("engine/core/math")

local visual_data = require("resources/visual_data")

local painter = {}

function painter.draw_background()
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

return painter
