local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local input = require("engine/input/input")
local text_helper = require("engine/ui/text_helper")

local menu_item = require("menu/menu_item")
local text_menu = require("menu/text_menu_with_sfx")
local gameplay_data = require("resources/gameplay_data")

-- main menu: gamestate for player navigating in main menu
local main_menu = derived_class(gamestate)

main_menu.type = ':main_menu'

-- sequence of menu items to display, with their target states
main_menu.items = transform({
    {"start", function(app)
      app.managers[':adventure'].next_step = 'intro'
      flow:query_gamestate_type(':adventure')
    end},
--#if cheat
    {"debug: tutorial fight", function(app)
      app.managers[':fight'].next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_fighter_id]
      flow:query_gamestate_type(':fight')
    end},
    {"debug: 1f fight", function(app)
      app.game_session.floor_number = 1
      app.game_session.fight_count = 10  -- just to avoid tutorials
      -- don't let Rossmann send you back to 1F after fight
      app.game_session:register_met_npc(gameplay_data.rossmann_fighter_id)
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = gameplay_data.max_hp_after_first_tutorial
      pc_fighter_prog.known_attack_ids = {1, 7}  -- learned from rossmann
      pc_fighter_prog.known_reply_ids = {}
      app.managers[':adventure'].next_step = 'floor_loop'
      flow:query_gamestate_type(':adventure')
    end},
    {"debug: 3f fight", function(app)
      app.game_session.floor_number = 3
      app.game_session.fight_count = 10  -- just to avoid tutorials
      -- don't let Rossmann send you back to 1F after fight
      app.game_session:register_met_npc(gameplay_data.rossmann_fighter_id)
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = gameplay_data.max_hp_after_win_by_floor_number[2]
      pc_fighter_prog.known_attack_ids = {1, 7, 4, 5, 6, 4, 12}
      pc_fighter_prog.known_reply_ids = {4, 9, 5}
      app.managers[':adventure'].next_step = 'floor_loop'
      flow:query_gamestate_type(':adventure')
    end},
    {"debug: rossmann fight", function(app)
      app.game_session.floor_number = 5
      app.game_session.fight_count = 10  -- just to avoid tutorials
      -- don't let Rossmann send you back to 1F after fight
      app.game_session:register_met_npc(gameplay_data.rossmann_fighter_id)
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = gameplay_data.max_hp_after_win_by_floor_number[4]
      pc_fighter_prog.known_attack_ids = {1, 7, 4, 5, 6, 4, 12}
      pc_fighter_prog.known_reply_ids = {4, 9, 5}
      app.managers[':adventure'].next_step = 'floor_loop'
      flow:query_gamestate_type(':adventure')
    end},
    {"debug: boss floor", function(app)
      app.game_session.floor_number = #gameplay_data.floors  -- last floor
      app.game_session.fight_count = 10  -- high count to avoid unwanted tutorials
      -- don't let Rossmann send you back to 1F after fight
      app.game_session:register_met_npc(gameplay_data.rossmann_fighter_id)
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = gameplay_data.max_hp_after_win_by_floor_number[4]
      pc_fighter_prog.known_attack_ids = {1, 2, 3, 4, 5, 6, 7, 8, 10}
      pc_fighter_prog.known_reply_ids = {1, 3, 4, 5, 6, 8, 9, 10}
      app.managers[':adventure'].next_step = 'floor_loop'
      flow:query_gamestate_type(':adventure')
    end},
    {"debug: boss fight", function(app)
      app.game_session.floor_number = #gameplay_data.floors  -- last floor
      app.game_session.fight_count = 10
      -- don't let Rossmann send you back to 1F after fight
      app.game_session:register_met_npc(gameplay_data.rossmann_fighter_id)
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = gameplay_data.max_hp_after_win_by_floor_number[4]
      pc_fighter_prog.known_attack_ids = {1, 2, 3, 4, 5, 6, 7, 8, 10}
      pc_fighter_prog.known_reply_ids = {1, 3, 4, 5, 6, 8, 9, 10}
      app.managers[':fight'].next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.ceo_fighter_id]
      flow:query_gamestate_type(':fight')
    end},
--#endif
--#if sandbox
    {"debug man fight", function(app)
      app.game_session.floor_number = 1
      app.game_session.fight_count = 10
      local pc_fighter_prog = app.game_session.pc_fighter_progression
      pc_fighter_prog.max_hp = 10
      pc_fighter_prog.known_attack_ids = {}
      pc_fighter_prog.known_reply_ids = {3, 4, 9}
      app.managers[':fight'].next_opponent = app.game_session.npc_fighter_progressions[7]
      flow:query_gamestate_type(':fight')
    end},
    {"debug: sandbox", function(app)
      flow:query_gamestate_type(':sandbox')
    end}
--#endif
  }, unpacking(menu_item))

-- text_menu: text_menu    component handling menu display and selection
function main_menu:init()
  gamestate.init(self)

  -- component (wait for start to create text_menu so app has been registered)
  self.text_menu = nil
end

function main_menu:on_enter()
  self.text_menu = text_menu(self.app, 5, alignments.horizontal_center, colors.white)
  self.text_menu:show_items(main_menu.items)
end

function main_menu:update()
  self.text_menu:update()
end

function main_menu:render()
  self:draw_title()
  self.text_menu:draw(screen_width / 2, 72)
  self:draw_instructions()
end

function main_menu:draw_title()
  local y = 14
  text_helper.print_centered("* wit fighter *", 64, y, colors.white)
  y = y + 8
  -- #version
  -- PICO-8 cannot read data/version.txt, so exceptionally set the version manually here
  text_helper.print_centered("v1.0+", 64, y, colors.white)
  y = y + 8
  text_helper.print_centered("by komehara", 64, y, colors.white)
end

function main_menu:draw_instructions()
  local y = 49
  text_helper.print_centered(text_helper.wwrap("learn verbal attacks and matching replies", 25), 64, y, colors.white)
  y = y + 15
  text_helper.print_centered(text_helper.wwrap("win to reach the top!", 25), 64, y, colors.white)

  y = 110
  api.print("arrows: navigate", 33, y, colors.white)
  y = y + 6
  api.print("z/c/n: confirm", 33, y, colors.white)
  y = y + 6
  api.print("x/v/m: cancel", 33, y, colors.white)
end

return main_menu
