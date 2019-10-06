local gamestate = require("engine/application/gamestate")
require("engine/core/class")
require("engine/core/math")
require("engine/render/color")
local ui = require("engine/ui/ui")

local quote_info = require("content/quote_info")
local menu_item = require("menu/menu_item")
local text_menu = require("menu/text_menu")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

-- wit fight: in-game gamestate for fighting an opponent
local wit_fight = derived_class(gamestate)

wit_fight.type = ':wit_fight'

-- components
--   quote_menu    text_menu       to select next quote to say
-- state
--   floor_number  int             current floor the player character is on
--   npc_info      (npc_info|nil)  opponent npc info (nil until fight starts)
--   pc_quote      (quote|nil)     current quote used by the pc  (nil if not currently using a quote)
--   npc_quote     (quote|nil)     current quote used by the npc (nil if not currently using a quote)
function wit_fight:_init(app)
  gamestate._init(self, app)

  -- menu items will be filled dynamically
  self.quote_menu = text_menu({}, alignments.left, colors.dark_blue)

  self.floor_number = 1
  self.npc_info = nil
  self.pc_quote = nil
  self.npc_quote = nil
end

function wit_fight:on_enter()
  self:start_fight_with_random_npc()

  -- for text demo
  self:fill_quote_menu()
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

-- flow

function wit_fight:start_fight_with_random_npc()
  local random_npc_info = self:pick_non_recent_random_npc_info()
  self:start_fight_with(random_npc_info)
end

function wit_fight:pick_non_recent_random_npc_info()
  local candidate_npc_info_s = self:get_candidate_npc_info_sequence()
  return pick_random(candidate_npc_info_s)
end

function wit_fight:get_candidate_npc_info_sequence()
  local floor_info = gameplay_data:get_floor_info(self.floor_number)

  local candidate_npc_info_s = {}
  for level = floor_info.npc_level_min, floor_info.npc_level_max do
    local npc_info_s = gameplay_data:get_npc_info_table_with_level(level)
    for npc_info in all(npc_info_s) do
      add(candidate_npc_info_s, npc_info)
    end
  end

  return candidate_npc_info_s
end

function wit_fight:start_fight_with(npc_info)
  self.npc_info = npc_info
  -- load npc sprite
  -- start battle flow
  -- mock quote
  self:npc_say_quote(gameplay_data.attacks[12])
end

function wit_fight:pc_say_quote(quote_info)
  self.pc_quote = quote_info
  self.npc_quote = nil
end

function wit_fight:npc_say_quote(quote_info)
  self.npc_quote = quote_info
  self.pc_quote = nil
end

-- ui

function wit_fight:fill_quote_menu()
  local known_quotes

  if #self.app.game_session.pc_known_quotes > 0 then
    known_quotes = self.app.game_session.pc_known_quotes
  else
    -- prepare dummy quote so the menu is not empty
    -- player will see this at the beginning of the game ("start with nothing")
    --  and when all other options have already been used
    -- for now, just attack
    known_quotes = {quote_info(0, quote_types.attack, 0, "...")}
  end

  for quote in all(known_quotes) do
    add(self.quote_menu.items, menu_item(quote.text, function ()
      self:pc_say_quote(quote)
    end))
  end
end

-- render

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

  if self.npc_info then
    visual_data.sprites.npc[self.npc_info.id]:render(vector(86, 78))
  end
end

function wit_fight:draw_hud()
  self:draw_floor_number()
  self:draw_quote_bubble()
  self:draw_health_bars()
  self:draw_bottom_box()
  self:draw_npc_label()
end

function wit_fight:draw_floor_number()
  ui.draw_box(43, 1, 84, 9, colors.black, colors.orange)
  ui.print_centered("floor "..tostr(self.floor_number), 64, 6, colors.black)
end

function wit_fight:draw_quote_bubble()
  -- ui params
  local pc_bubble_tail_tip = vector(21, 38)
  local npc_bubble_tail_tip = vector(84, 38)

  local should_draw_quote_bubble = false
  local bubble_tail_tip = nil
  local bubble_text = nil

  -- pc has priority, but normally we shouldn't set both quotes at the same time
  if self.pc_quote then
    bubble_tail_tip = pc_bubble_tail_tip
    bubble_text = self.pc_quote.text
    should_draw_quote_bubble = true
  elseif self.npc_quote then
    bubble_tail_tip = npc_bubble_tail_tip
    bubble_text = self.npc_quote.text
    should_draw_quote_bubble = true
  end

  if should_draw_quote_bubble then
    -- draw bubble
    ui.draw_rounded_box(5, 20, 123, 34, colors.black, colors.white)
    visual_data.sprites.bubble_tail:render(bubble_tail_tip)

    -- print quote
    api.print(wwrap(bubble_text, visual_data.bubble_line_width), 7, 22, colors.black)
  end
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

function wit_fight:draw_npc_label()
  if self.npc_info then
    ui.draw_rounded_box(51, 79, 121, 87, colors.indigo, colors.white)
    ui.print_centered(self.npc_info.name, 86, 84, colors.black)
  end
end

return wit_fight
