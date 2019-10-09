local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
require("engine/core/class")
local input = require("engine/input/input")
require("engine/render/color")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local text_menu = require("menu/text_menu")

-- main menu: gamestate for player navigating in main menu
local main_menu = derived_class(gamestate)

main_menu.type = ':main_menu'

-- sequence of menu items to display, with their target states
main_menu._items = transform({
    {"start", function() flow:query_gamestate_type(':adventure') end}
  }, unpacking(menu_item))

-- text_menu: text_menu    component handling menu display and selection
function main_menu:_init(app)
  gamestate._init(self, app)

  self.text_menu = text_menu(main_menu._items, alignments.center, colors.white)
end

function main_menu:on_enter()
  -- do not reset previous selection to retain last user choice
end

function main_menu:on_exit()
end

function main_menu:update()
  self.text_menu:update()
end

function main_menu:render()
  self:draw_title()
  self.text_menu:draw(screen_width / 2, 46)
  self:draw_instructions()
end

function main_menu:draw_title()
  local y = 14
  ui.print_centered("* wit fighter *", 64, y, colors.white)
  y = y + 8
  ui.print_centered("by komehara", 64, y, colors.white)
end

function main_menu:draw_instructions()
  local y = 66
  ui.print_centered(wwrap("learn verbal attacks and matching replies", 25), 64, y, colors.white)
  y = y + 15
  ui.print_centered(wwrap("win to reach the top!", 25), 64, y, colors.white)

  y = 96
  api.print("arrows: navigate", 33, y, colors.white)
  y = y + 6
  api.print("z/c/n: confirm", 33, y, colors.white)
  y = y + 6
  api.print("x/v/m: cancel", 33, y, colors.white)
end

return main_menu
