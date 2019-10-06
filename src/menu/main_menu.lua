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
    {"start", function() flow:query_gamestate_type(':wit_fight') end}
  }, unpacking(menu_item))

-- text_menu: text_menu    component handling menu display and selection
function main_menu:_init()
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
  local y = 48
  ui.print_centered("wit fighter", 64, y, colors.white)
  y = y + 8
  ui.print_centered("by komehara", 64, y, colors.white)
  y = y + 4 * character_height

  -- skip 4 lines and draw menu content
  self.text_menu:draw(screen_width / 2, y)
end

return main_menu
