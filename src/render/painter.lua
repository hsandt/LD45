local graphics_helper = require("engine/ui/graphics_helper")
local text_helper = require("engine/ui/text_helper")

local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

local painter = {}

function painter.draw_background(floor_number)
  local zone = gameplay_data:get_zone(floor_number)
  if zone < 4 then
    painter.draw_background_stairs(zone)
  else
    painter.draw_background_ceo_room()
  end
end

function painter.draw_background_stairs(zone)
  local sprites = visual_data.sprites

  local zone_paint_info = visual_data.zone_paint_info_t[zone]

  -- wall
  rectfill(0, 0, 127, 127, zone_paint_info.wall_color)

  -- floor
  rectfill(0, 51, 103, 127, zone_paint_info.floor_color)
  line(0, 50, 104, 50, colors.black)
  line(104, 50, 104, 127, colors.black)

  -- switch color palette for stairs so they match the floor color
  pal(colors.light_gray, zone_paint_info.floor_color)

  -- upper stairs
  sprites.upper_stairs_step1:render(vector(104, 45))
  local pos = vector(110, 40)
  for i = 1, 3 do
    sprites.upper_stairs_step2:render(pos)
    pos = pos + vector(6, -6)
  end

  -- lower stairs
  sprites.lower_stairs_step:render(vector(104, 80))
  sprites.lower_stairs_step:render(vector(110, 84))

  -- reset palette switch
  pal()
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
  rect(103, 54, 120, 94, colors.black)
  line(104, 83, 119, 83, colors.black)
  rectfill(104, 55, 119, 82, colors.orange)
  rectfill(104, 84, 119, 93, colors.brown)
end

function painter.draw_floor_number(floor_number)
  graphics_helper.draw_box(110, 65, 124, 73, colors.black, colors.orange)
  text_helper.print_centered(floor_number.."f", 117, 69, colors.black)
end

return painter
