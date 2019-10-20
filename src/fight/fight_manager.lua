require("engine/core/class")
require("engine/core/math")
require("engine/render/color")
local ui = require("engine/ui/ui")

local flow = require("engine/application/flow")
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

function fight_manager:set_next_opponent_to_matching_random_npc()
  self.next_opponent = self:pick_matching_random_npc_fighter_prog()
end

function fight_manager:pick_matching_random_npc_fighter_prog()
  local candidate_npc_fighter_prog_s = self:get_all_candidate_npc_fighter_prog(self.app.game_session.floor_number)
  return pick_random(candidate_npc_fighter_prog_s)
end

function fight_manager:get_all_candidate_npc_fighter_prog(floor_number)
  local floor_info = gameplay_data:get_floor_info(floor_number)

  local candidate_npc_fighter_prog_s = {}
  for level = floor_info.npc_level_min, floor_info.npc_level_max do
    local npc_info_s = self.app.game_session:get_all_npc_fighter_progressions_with_level(level)
    for npc_info in all(npc_info_s) do
      add(candidate_npc_fighter_prog_s, npc_info)
    end
  end

  return candidate_npc_fighter_prog_s
end

function fight_manager:start_fight_with_next_opponent()
  assert(self.next_opponent, "fight_manager:start_fight_with_next_opponent: next opponent not set")
  self:start_fight_with(self.next_opponent)
  self.next_opponent = nil
end

function fight_manager:start_fight_with(opponent_fighter_prog)
  self:load_fighters(self.app.game_session.pc_fighter_progression, opponent_fighter_prog)

  -- start battle flow (opponent starts)
  self.active_fighter_index = 2
  self:request_active_fighter_action()
end

function fight_manager:stop_fight()
  self.active_fighter_index = 0
  self:unload_fighters()
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
  -- char reference is local, so pc_fighter effectively becomes its owner
  -- (destroying fighter in unload_fighters will be enough to clear both via garbage collection)
  local pc_fighter = fighter(char, pc_fighter_prog)
  return pc_fighter
end

-- npc_fighter_prog: fighter_progression
-- static
function fight_manager.generate_npc_fighter(npc_fighter_prog)
  -- retrieve character info from npc fighter progression
  local char_info = gameplay_data.npc_info_s[npc_fighter_prog.fighter_info.character_info_id]
  local char = character(char_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
  -- char reference is local, so npc_fighter effectively becomes its owner
  -- (destroying fighter in unload_fighters will be enough to clear both via garbage collection)
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
  local available_quote_ids = human_fighter:get_available_quote_ids(quote_type)

  if #available_quote_ids == 0 then
    -- no quotes left
    if quote_type == quote_types.attack then
      -- pc has nothing to say to attack, just skip this turn and let opponent attack
      -- (last quotes have already been cleared at this point)
      self:request_next_fighter_action()
      return
    else  -- quote_type == quote_types.reply
      -- pc must still reply to close the exchange, give losing quote
      add(available_quote_ids, -1)
    end
  end

  local items = self:generate_quote_menu_items(human_fighter, quote_type, available_quote_ids)
  self.app.managers[':dialogue']:prompt_items(items)
end

-- it's a bit weird to pass available_quote_ids whereas we could get them from human_fighter
-- but we do it because we need to check if they are empty first in request_human_fighter_action,
--   to either add a dummy reply or completely skip the active turn if no attack available
--   (and returning is done before even calling this method)
function fight_manager:generate_quote_menu_items(human_fighter, quote_type, available_quote_ids)
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

  if #available_quote_ids == 0 then
    -- ai has nothing to say, whether attack or reply, add losing quote
    add(available_quote_ids, -1)
  end

  local random_quote_id = pick_random(available_quote_ids)
  local random_quote = gameplay_data:get_quote(quote_type, random_quote_id)
  self.app:wait_and_do(visual_data.ai_say_quote_delay, self.say_quote, self, ai_fighter, random_quote)
end

function fight_manager:say_quote(active_fighter, quote)
  printh("say_quote")
  -- don't wait for input, since either the quote menu (pc replying), the auto play (npc replying),
  --   or the quote match resolution (if saying a reply) will hide that text eventually
  active_fighter.character.speaker:say(quote.text)
  active_fighter.last_quote = quote

  if quote.quote_type == quote_types.attack then
    if quote.id == -1 then
      -- active fighter said losing quote, no need to ask opponent for reply
      -- immediately resolve with attacker's loss
      self.app:wait_and_do(visual_data.resolve_losing_attack_delay,
        self.resolve_losing_attack, self, active_fighter, self:get_active_fighter_opponent())
    else
      -- normal quote was said
      self.app:wait_and_do(visual_data.request_reply_delay,
        self.request_next_fighter_action, self)
    end
  else  -- quote.quote_type == quote_types.reply
    -- last quote of opponent should be attack, and active fighter has replied
    self.app:wait_and_do(visual_data.resolve_exchange_delay,
      self.resolve_exchange, self, self:get_active_fighter_opponent(), active_fighter)
  end
end

function fight_manager:request_next_fighter_action()
  self:give_control_to_next_fighter()
  self:request_active_fighter_action()
end

function fight_manager:resolve_losing_attack(losing_attacker, passive_replier)
  self:hit_fighter(attacker, gameplay_data.losing_attack_penalty)
  self.app:wait_and_do(visual_data.check_exchange_result_delay,
    self.check_exchange_result, self, attacker, passive_replier)
end

-- attacker: fighter
-- replier: fighter
function fight_manager:resolve_exchange(attacker, replier)
  printh("resolve_exchange")

  local attacker_quote = attacker.last_quote
  local replier_quote = replier.last_quote

--#if assert
  assert(attacker_quote.quote_type == quote_types.attack)
  assert(replier_quote.quote_type == quote_types.reply)
--#endif

  local match_power = gameplay_data:get_quote_match_power(attacker_quote, replier_quote)

  -- A match power of 0 is accepted to cancel an attack. -1, however, means the reply failed completely.
  if match_power >= 0 then
    -- don't use the reply level, but the match power to determine how good the counter is
    self:hit_fighter(attacker, match_power)
  else
    -- reply failed, just use the attack level directly to deal damage
    self:hit_fighter(replier, attacker_quote.level)
  end

  printh("wait_and_do: check_exchange_result")
  self.app:wait_and_do(visual_data.check_exchange_result_delay,
    self.check_exchange_result, self, attacker, replier)
end

function fight_manager:check_exchange_result(attacker, replier)
  printh("check_exchange_result")
  self:clear_exchange()

  local is_attacker_alive = attacker:is_alive()
  local is_replier_alive = replier:is_alive()
  if is_attacker_alive and is_replier_alive then
    printh("both fighters still alive, request active fighter action")
    -- in our rules, replying fighter keeps control whatever the result of the exchange,
    --   but becomes attacker, so just continue to next action
    self.app:wait_and_do(visual_data.request_active_fighter_action_delay,
      self.request_active_fighter_action, self)
  elseif is_attacker_alive then
    self:start_victory(attacker)
  else
    self:start_victory(replier)
  end
end

function fight_manager:clear_exchange()
  for fighter in all(self.fighters) do
    -- consume quotes to avoid replying again next turn
    fighter.last_quote = nil
    -- clear quote bubbles
    fighter.character.speaker:stop()
  end
end

function fight_manager:hit_fighter(some_fighter, damage)
  printh("hit_fighter: "..some_fighter.character.character_info.name.." with "..tostr(damage))
  some_fighter:take_damage(damage)

  -- todo: fx and sfx
end

function fight_manager:start_victory(some_fighter)
  if some_fighter.fighter_progression.character_type == character_types.human then
    printh("player wins")
    -- flow allows re-entering the same state, it will call on_exit and on_enter
    self:stop_fight()
    self.next_opponent = self:pick_matching_random_npc_fighter_prog()
    flow:query_gamestate_type(':fight')
  else  -- some_fighter.fighter_progression.character_type == character_types.ai
    printh("ai wins")
    self:stop_fight()
    self.next_opponent = self:pick_matching_random_npc_fighter_prog()
    flow:query_gamestate_type(':fight')
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
end

function fight_manager:draw_floor_number()
  ui.draw_box(43, 1, 84, 9, colors.black, colors.orange)
  ui.print_centered("floor "..tostr(self.app.game_session.floor_number), 64, 5, colors.black)
end

return fight_manager
