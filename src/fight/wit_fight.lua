local gamestate = require("engine/application/gamestate")
require("engine/core/class")
require("engine/render/color")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local text_menu = require("menu/text_menu")
local visual_data = require("resources/visual_data")

-- wit fight: in-game gamestate for fighting an opponent
local wit_fight = derived_class(gamestate)

wit_fight.type = ':wit_fight'

-- state
-- quote_menu  text_menu  to select next quote to say
function wit_fight:_init()
  -- menu items will be filled dynamically
  self.quote_menu = text_menu({}, alignments.left, colors.dark_blue)
end

function wit_fight:on_enter()
  -- for text demo
  add(self.quote_menu.items, menu_item("demo quote", function ()
    printh("test demo quote menu")
  end))
  add(self.quote_menu.items, menu_item("demo quote 2", function ()
    printh("test demo quote menu 2")
  end))
end

function wit_fight:on_exit()
end

function wit_fight:update()
  self.quote_menu:update()
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
  visual_data.sprites.pc:render(vector(19, 78))
  visual_data.sprites.npc1:render(vector(86, 78))
end

function wit_fight:draw_hud()
  self:draw_floor_number()
  self:draw_quote_bubble()
  self:draw_health_bars()
  self:draw_bottom_box()
end

function wit_fight:draw_floor_number()
  ui.draw_box(43, 1, 84, 9, colors.black, colors.orange)
  ui.print_centered("floor 12", 64, 6, colors.black)
end

function wit_fight:draw_quote_bubble()
  ui.draw_rounded_box(5, 20, 123, 34, colors.black, colors.white)

  -- draw bubble tail
  local pc_bubble_tail_tip = vector(21, 38)
  local npc_bubble_tail_tip = vector(84, 38)
  visual_data.sprites.bubble_tail:render(pc_bubble_tail_tip)
  visual_data.sprites.bubble_tail:render(npc_bubble_tail_tip)

  -- draw demo text
  api.print("1234567890123456789012345678!\n1234567890123456789012345678!", 7, 22, colors.black)
end

function wit_fight:draw_health_bars()
  -- player character health
  ui.draw_box(5, 42, 9, 78, colors.dark_blue, colors.blue)

  -- npc health
  ui.draw_box(96, 42, 100, 78, colors.dark_blue, colors.blue)
end

function wit_fight:draw_bottom_box()
  ui.draw_rounded_box(0, 89, 127, 127, colors.dark_blue, colors.indigo)

  -- menu content
  self.quote_menu:draw(2, 91)
end

return wit_fight
