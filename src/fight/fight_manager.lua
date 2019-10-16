require("engine/core/class")
require("engine/core/math")
require("engine/render/color")
local ui = require("engine/ui/ui")

local manager = require("engine/application/manager")

local quote_info = require("content/quote_info")
local fighter = require("fight/fighter")
local menu_item = require("menu/menu_item")
local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

local fight_manager = derived_class(manager)

fight_manager.type = ':fight'
fight_manager.initially_active = false

--[[
Parameters
  next_opponent         (fighter_progression|nil)  next opponent to start fight with, if any
  fighters              {fighter}                  current fighters. [1] is player, [2] is npc

State
  active_fighter_index  int                        index of fighter currently selecting action / acting
--]]
function fight_manager:_init()
  manager._init(self)

  self.next_opponent = nil
  self.fighters = {}

  self.active_fighter_index = 0  -- invalid index
end

function fight_manager:start()
end

function fight_manager:update()
end

function fight_manager:render()
  self:draw_fighters()
  self:draw_hud()
end

-- helpers

function fight_manager:get_active_fighter_opponent()
  return self.fighters[self:get_active_fighter_index_opponent()]
end

function fight_manager:get_active_fighter_index_opponent()
  return self.active_fighter_index % 2 + 1
end

function fight_manager:give_control_to_next_fighter()
  self.active_fighter_index = self:get_active_fighter_index_opponent()
end

function fight_manager:is_active_fighter_attacking()
  return self:get_active_fighter_opponent().last_quote == nil
end

-- flow

function fight_manager:start_fight_with_next_opponent()
  assert(self.next_opponent, "fight_manager:start_fight_with_next_opponent: next opponent not set")
  self:start_fight_with(self.next_opponent)
end

function fight_manager:start_fight_with(opponent_fighter_prog)
  self:load_fighters(self.app.game_session.pc_fighter_progression, opponent_fighter_prog)

  -- start battle flow (opponent starts)
  self.active_fighter_index = 2
  self:request_active_fighter_action()
end

function fight_manager:load_fighters(pc_fighter_prog, npc_fighter_prog)
  local pc_fighter = fight_manager.generate_pc_fighter(pc_fighter_prog)
  local npc_fighter = fight_manager.generate_npc_fighter(npc_fighter_prog)
  self.fighters = {pc_fighter, npc_fighter}

  -- register fighter character speaker components
  self.app.managers[':dialogue']:add_speaker(pc_fighter.character.speaker)
  self.app.managers[':dialogue']:add_speaker(npc_fighter.character.speaker)
end

function fight_manager:unload_fighters()
  for some_fighter in all(self.fighters) do
    self.app.managers[':dialogue']:remove_speaker(some_fighter.character.speaker)
  end

  clear_table(self.fighters)
end

-- pc_fighter_prog: fighter_progression
-- static
function fight_manager.generate_pc_fighter(pc_fighter_prog)
  -- retrieve character info from pc fighter progression
  local char_info = gameplay_data.pc_info
  local char = character(char_info, horizontal_dirs.right, visual_data.pc_sprite_pos)
  local pc_fighter = fighter(char, pc_fighter_prog)
  return pc_fighter
end

-- npc_fighter_prog: fighter_progression
-- static
function fight_manager.generate_npc_fighter(npc_fighter_prog)
  -- retrieve character info from npc fighter progression
  local char_info = gameplay_data.npc_info_s[npc_fighter_prog.fighter_info.character_info_id]
  local char = character(char_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
  local npc_fighter = fighter(char, npc_fighter_prog)
  return npc_fighter
end

function fight_manager:request_active_fighter_action()
  self:request_fighter_action(self.fighters[self.active_fighter_index])
end

function fight_manager:request_fighter_action(active_fighter)
  if active_fighter.fighter_progression.character_type == character_types.human then
    self:request_human_fighter_action(active_fighter)
  else
    self:request_ai_fighter_action(active_fighter)
  end
end

function fight_manager:request_human_fighter_action(human_fighter)
--#if assert
  assert(self.fighters[self.active_fighter_index] == human_fighter)
  assert(human_fighter.fighter_progression.character_type == character_types.human)
--#endif

  local quote_type = self:is_active_fighter_attacking() and quote_types.attack or quote_types.reply
  local items = self:generate_quote_menu_items(human_fighter, quote_type)
  self.app.managers[':dialogue']:prompt_items(items)
end

function fight_manager:generate_quote_menu_items(human_fighter, quote_type)
  local available_quote_ids = human_fighter:get_available_quote_ids(quote_type)
  if #available_quote_ids == 0 then
    add(available_quote_ids, 0)
  end

  return transform(available_quote_ids, function (quote_id)
    local quote = gameplay_data:get_quote(quote_type, quote_id)
    local say_quote_callback = function ()
      self:say_quote(human_fighter, quote)
    end
    return menu_item(quote.text, say_quote_callback)
  end)
end

function fight_manager:request_ai_fighter_action(ai_fighter)
--#if assert
  assert(self.fighters[self.active_fighter_index] == ai_fighter)
  assert(ai_fighter.fighter_progression.character_type == character_types.ai)
--#endif

  local quote_type = self:is_active_fighter_attacking() and quote_types.attack or quote_types.reply
  local available_quote_ids = ai_fighter:get_available_quote_ids(quote_type)
  local random_quote_id = pick_random(available_quote_ids)
  local random_quote = gameplay_data:get_quote(quote_type, random_quote_id)
  self:start_wait_and_say_quote(ai_fighter, random_quote)
end

function fight_manager:start_wait_and_say_quote(active_fighter, quote)
  self.app:start_coroutine(self.wait_and_say_quote, self, active_fighter, quote)
end

function fight_manager:wait_and_say_quote(active_fighter, quote)
  self.app:yield_delay_s(2)
  self:say_quote(active_fighter, quote)
end

function fight_manager:say_quote(active_fighter, quote)
  -- don't wait for input, since either the quote menu (pc replying), the auto play (npc replying),
  --   or the quote match resolution (if saying a reply) will hide that text eventually
  active_fighter.character.speaker:say(quote.text)
  active_fighter.last_quote = quote

  if quote.quote_type == quote_types.attack then
    self:give_control_to_next_fighter()
    self:request_active_fighter_action()
  else  -- quote.quote_type == quote_types.reply
    -- last quote of opponent should be attack
    self:resolve_exchange(self:get_active_fighter_opponent(), active_fighter)
  end
end

-- attacker: fighter
-- replier: fighter
function fight_manager:resolve_exchange(attacker, replier)
--#if assert
  assert(attacker.last_quote.quote_type == quote_types.attack)
  assert(replier.last_quote.quote_type == quote_types.reply)
--#endif

  local successful_reply = gameplay_data:are_quote_matching(attacker.last_quote, replier.last_quote)
  if successful_reply then
    self:hit_fighter(attacker, 1)
  else
    self:hit_fighter(replier, 1)
  end

  -- consume quotes to avoid replying again next turn
  attacker.last_quote = nil
  replier.last_quote = nil

  local is_attacker_alive = attacker.is_alive()
  local is_replier_alive = replier.is_alive()
  if is_attacker_alive and is_replier_alive then
    -- in our rules, replying fighter keeps control whatever the result of the exchange,
    --   but becomes attacker, so just continue to next action
    self:request_active_fighter_action()
  elseif is_attacker_alive then
    self:start_victory(attacker)
  else
    self:start_victory(replier)
  end
end

function fight_manager:hit_fighter(some_fighter, damage)
  some_fighter:take_damage(damage)

  -- todo: fx and sfx
end

function fight_manager:start_victory(some_fighter)
  if some_fighter.fighter_progression.character_type == character_types.human then
    log("player wins")
  else  -- some_fighter.fighter_progression.character_type == character_types.ai
    log("ai wins")
  end
end

-- ui


-- render

function fight_manager:draw_fighters()
  for fighter in all(self.fighters) do
    fighter:draw()
  end
end

function fight_manager:draw_hud()
  self:draw_floor_number()
  self:draw_health_bars()
  self:draw_npc_label()
end

function fight_manager:draw_floor_number()
  ui.draw_box(43, 1, 84, 9, colors.black, colors.orange)
  ui.print_centered("floor "..tostr(self.floor_number), 64, 6, colors.black)
end

function fight_manager:draw_health_bars()
  -- player character health
  ui.draw_box(5, 42, 9, 78, colors.dark_blue, colors.blue)

  -- npc health
  ui.draw_box(96, 42, 100, 78, colors.dark_blue, colors.blue)
end

function fight_manager:draw_npc_label()
  if self.npc_info then
    ui.draw_rounded_box(51, 79, 121, 87, colors.indigo, colors.white)
    ui.print_centered(self.npc_info.name, 86, 84, colors.black)
  end
end

return fight_manager
