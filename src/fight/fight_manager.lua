require("engine/core/class")
require("engine/core/math")
require("engine/render/color")

local flow = require("engine/application/flow")
local manager = require("engine/application/manager")
local animated_sprite = require("engine/render/animated_sprite")

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
Dynamic parameters (fixed for a given fight)
  next_opponent         fighter_progression|nil    next opponent to start fight with, if any
  fighters              {fighter}                  current fighters. [1] is player, [2] is npc

State
  active_fighter_index  int                        index of fighter currently selecting action / acting
  won_last_fight        bool|nil                   true iff player won the last fight, if any
  hit_fx                animated_sprite            hit fx animated sprite
  hit_fx_pos            vector|nil                 position of the hit fx animated sprite, if any
  hit_feedback_label    ui.label|nil               label for hit feedback (set reference directly)
--]]
function fight_manager:_init()
  manager._init(self)

  self.next_opponent = nil
  self.fighters = {}

  self.active_fighter_index = 0  -- invalid index
  self.won_last_fight = nil

  self.hit_fx = animated_sprite(visual_data.anim_sprites.hit_fx)
  self.hit_fx_pos = nil

  self.hit_feedback_label = nil
end

function fight_manager:start()  -- override
end

function fight_manager:update()  -- override
  -- we should have some animated sprite manager updating all sprites, but for now we do it ourselves
  self:update_fighters()
  self.hit_fx:update()
end

function fight_manager:render()  -- override
  self:draw_fighters()

  -- we should have some fx manager rendering all fx, but for now we do it ourselves
  self.hit_fx:render(self.hit_fx_pos)

  -- hud on top of everything
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

function fight_manager:pick_matching_random_npc_fighter_prog()
  local candidate_npc_fighter_prog_s = self:get_all_candidate_npc_fighter_prog(self.app.game_session.floor_number)
  assert(#candidate_npc_fighter_prog_s > 0, "no candidate npc found at floor "..self.app.game_session.floor_number)
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
  -- do not consume next_opponent now, it will be checked at the beginning of
  --   adventure_state:_play_floor_loop as the previous opponent
end

function fight_manager:start_fight_with(opponent_fighter_prog)
  self:spawn_fighters(self.app.game_session.pc_fighter_progression, opponent_fighter_prog)

  -- start battle flow (opponent starts)
  self.active_fighter_index = 2
  self:request_active_fighter_action()
end

function fight_manager:stop_fight()
  -- learning
  for some_fighter in all(self.fighters) do
    some_fighter:update_learned_quotes()
  end

  -- update count
  self.app.game_session:increment_fight_count()

  -- cleanup
  self.active_fighter_index = 0
  self:despawn_fighters()
end

function fight_manager:spawn_fighters(pc_fighter_prog, npc_fighter_prog)
  local dm = self.app.managers[':dialogue']

  local pc_fighter = self:generate_pc_fighter(pc_fighter_prog)
  local npc_fighter = self:generate_npc_fighter(npc_fighter_prog)
  self.fighters = {pc_fighter, npc_fighter}

  log("loaded fighters: "..pc_fighter:get_name().." vs "..npc_fighter:get_name(), 'itest')
end

-- pc_fighter_prog: fighter_progression
-- UB unless adventure manager has created pc as a character with same id
--   as pc_fighter_prog's fighter_info
function fight_manager:generate_pc_fighter(pc_fighter_prog)
  local am = self.app.managers[':adventure']

  -- usually the pc has been spawned in the previous adventure state,
  --   but it may not have been (e.g. in debug when starting a fight immediately),
  --   so lazily spawn character if needed
  if not am.pc then
    am:spawn_pc()
  end

  -- attach fighter to pre-existing (or lazily created) character in adventure manager
  -- do not register fighter character speaker, let adventure manager
  --   handle that when character arrives in the adventure state
  local pc_fighter = fighter(am.pc, pc_fighter_prog)
  return pc_fighter
end

-- npc_fighter_prog: fighter_progression
-- UB unless adventure manager has created npc as a character with same id
--   as npc_fighter_prog's fighter_info
function fight_manager:generate_npc_fighter(npc_fighter_prog)
  local am = self.app.managers[':adventure']

  -- usually the npc has been spawned in the previous adventure state,
  --   but it may not have been (e.g. in debug when starting a fight immediately),
  --   so lazily spawn character if needed
  if not am.npc then
    am:spawn_npc(npc_fighter_prog.fighter_info.character_info_id)
  end

  -- attach fighter to pre-existing (or lazily created) npc in adventure manager
  -- do not register fighter character speaker, let adventure manager
  --   handle that when character arrives in the adventure state
  local npc_fighter = fighter(am.npc, npc_fighter_prog)
  return npc_fighter
end

function fight_manager:despawn_fighters()
  -- do not unregister fighter character speakers, let adventure manager
  --   handle that when character leaves in the adventure state

  clear_table(self.fighters)
end

function fight_manager:request_active_fighter_action()
  self:request_fighter_action(self.fighters[self.active_fighter_index])
end

function fight_manager:request_fighter_action(active_fighter)
  if active_fighter.fighter_progression.character_type == character_types.pc then
    self:request_human_fighter_action(active_fighter)
  else
    self:request_ai_fighter_action(active_fighter)
  end
end

function fight_manager:request_human_fighter_action(human_fighter)
  assert(self.fighters[self.active_fighter_index] == human_fighter)
  assert(human_fighter.fighter_progression.character_type == character_types.pc)

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

  -- for debugging, allow ai control over pc
  if human_fighter.fighter_progression.control_type == control_types.human then
    local items = self:generate_quote_menu_items(human_fighter, quote_type, available_quote_ids)
    self.app.managers[':dialogue']:prompt_items(items)
  else  -- control_types.ai
    -- DEBUG
    -- pick quote and say it automatically like an ai
    local next_quote = self:auto_pick_quote(human_fighter, quote_type)
    self.app:wait_and_do(visual_data.ai_say_quote_delay, self.say_quote, self, human_fighter, next_quote)
  end
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
  assert(self.fighters[self.active_fighter_index] == ai_fighter)
  assert(ai_fighter.fighter_progression.character_type == character_types.npc)

  local quote_type = self:is_active_fighter_attacking() and quote_types.attack or quote_types.reply
  local available_quote_ids = ai_fighter:get_available_quote_ids(quote_type)

  if #available_quote_ids == 0 then
    -- ai has nothing to say, whether attack or reply, add losing quote
    add(available_quote_ids, -1)
  end

  -- npc always use ai control (we cannot plug human input into npc decisions currently)
  local next_quote = self:auto_pick_quote(ai_fighter, quote_type)

  self.app:wait_and_do(visual_data.ai_say_quote_delay, self.say_quote, self, ai_fighter, next_quote)
end

function fight_manager:auto_pick_quote(fighter, quote_type)
  if quote_type == quote_types.attack then
    return fighter:auto_pick_attack()
  else  -- quote_type == quote_types.reply
    local attack = self:get_active_fighter_opponent().last_quote
    assert(attack)
    return fighter:auto_pick_reply(attack.id)
  end
end

function fight_manager:say_quote(active_fighter, quote)
  local is_attacking = quote.type == quote_types.attack

  -- don't wait for input, since either the quote menu (pc replying), the auto play (npc replying),
  --   or the quote match resolution (if saying a reply) will hide that text eventually
  log("fighter '"..active_fighter:get_name().."' "..(is_attacking and "attacks" or "replies")..": ("..quote.id..") \""..quote.text.."\"", 'itest')
  active_fighter:say_quote(quote)  -- will set its last_quote

  if is_attacking then
    if quote.id == -1 then
      -- active fighter said losing quote, no need to ask opponent for reply
      -- immediately resolve with attacker's loss
      self.app:wait_and_do(visual_data.resolve_losing_attack_delay,
        self.resolve_losing_attack, self, active_fighter, self:get_active_fighter_opponent())
    else
      -- learning: replier receives quote and may remember it for later
      self:get_active_fighter_opponent():on_receive_quote(quote)

      -- normal quote was said
      self.app:wait_and_do(visual_data.request_reply_delay,
        self.request_next_fighter_action, self)
    end
  else  -- not is_attacking
    -- learning: attacker receives quote and may remember it for later
    self:get_active_fighter_opponent():on_receive_quote(quote)

    -- last quote of opponent should be attack, and active fighter has replied
    self.app:wait_and_do(visual_data.resolve_exchange_delay,
      self.resolve_exchange, self, self:get_active_fighter_opponent(), active_fighter)
  end
end

function fight_manager:request_next_fighter_action()
  self:give_control_to_next_fighter()
  self:request_active_fighter_action()
end

-- todo: losing attack is not interesting, replace with "i give up" or allow fighter
--   to reuse attacks already used after some turns
function fight_manager:resolve_losing_attack(losing_attacker, passive_replier)
  -- damage is not really due to attack or reply, but self failure, so pass quote_type = nil
  self:hit_fighter(losing_attacker, nil, gameplay_data.losing_attack_penalty)
  self.app:wait_and_do(visual_data.check_exchange_result_delay,
    self.check_exchange_result, self, losing_attacker, passive_replier)
end

-- attacker: fighter
-- replier: fighter
function fight_manager:resolve_exchange(attacker, replier)
  local attacker_quote = attacker.last_quote
  local replier_quote = replier.last_quote

  assert(attacker_quote.type == quote_types.attack)
  assert(replier_quote.type == quote_types.reply)

  local quote_match = gameplay_data:get_quote_match(attacker_quote, replier_quote)

  -- cancel_quote_match is used to cancel an attack
  -- a nil quote_match, however, means the reply failed completely
  if quote_match then
    -- reply worked
    -- don't use the reply level, but the match power to determine how good the counter is
    if quote_match.power > 0 then
      self:hit_fighter(attacker, quote_types.reply, quote_match.power)
    else
      -- either cancel quote or a specific match has power 0, so don't hit
      --   any character, but play neutralize feedback
      self:play_neutralize_feedback(attacker)
    end

    -- learning: both fighters witness quote match and can remember it
    --   (except cancel which automatically
    --   becomes available when cancel reply is learned)
    -- we check for directly inequality with cancel quote match, and not
    --   replier_quote.id > 0 (which wouldn't work for extra cancel replies we add later)
    -- nor
    --   quote_match.power > 0 (which would prevent learning normal replies which happen
    --     to be just good enough not to be hit on certain attacks only)
    if quote_match ~= gameplay_data.cancel_quote_match then
      attacker:on_witness_quote_match(quote_match)
      replier:on_witness_quote_match(quote_match)
    end
  else
    -- reply failed, just use the attack level directly to deal damage
    self:hit_fighter(replier, quote_types.attack, attacker_quote.level)
  end

  self.app:wait_and_do(visual_data.check_exchange_result_delay,
    self.check_exchange_result, self, attacker, replier)
end

function fight_manager:check_exchange_result(attacker, replier)
  self:clear_exchange()

  local is_attacker_alive = attacker:is_alive()
  local is_replier_alive = replier:is_alive()
  if is_attacker_alive and is_replier_alive then
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

function fight_manager:hit_fighter(target_fighter, quote_type, damage)
  target_fighter:take_damage(damage)

  -- anim
  self.app:start_coroutine(self._async_play_hurt_anim, self, target_fighter.character)

  -- fx
  local hit_fx_offset = visual_data.hit_fx_offset_right:copy()
  if target_fighter.direction == horizontal_dirs.left then
    hit_fx_offset:mirror_x()
  end
  -- use root_pos not sprite_pos, as the latter may change during _async_play_hurt_anim
  self.hit_fx_pos = target_fighter.character.root_pos + hit_fx_offset
  self.hit_fx:play('once')

  -- feedback message
  self.app:start_coroutine(self._async_show_hit_feedback_label, self, target_fighter, quote_type, damage)

  -- todo: sfx
end

function fight_manager:play_neutralize_feedback(target_fighter)
  -- todo
end

function fight_manager:_async_play_hurt_anim(fighter_character)
  local offset = visual_data.hurt_sprite_offset_right:copy()
  if fighter_character.direction == horizontal_dirs.left then
    offset:mirror_x()
  end
  -- original value was fighter_character.root_pos, so just add offset
  fighter_character.sprite_pos:add_inplace(offset)
  fighter_character.sprite:play('hurt')
  self.app:yield_delay_s(0.5)
  fighter_character.sprite_pos:copy_assign(fighter_character.root_pos)
  fighter_character.sprite:play('idle')
end

function fight_manager:_async_show_hit_feedback_label(target_fighter, quote_type, damage)
  -- losing attack has no hit feedback label
  local repr_damage = min(damage, 3)
  if quote_type then
    self.hit_feedback_label = visual_data.hit_feedback_labels[target_fighter.fighter_progression.character_type][quote_type][repr_damage]
--#if assert
    assert(self.hit_feedback_label, "no hit feedback label for (character type, quote type, representative damage): "..
      joinstr(", ", target_fighter.fighter_progression.character_type, quote_type, repr_damage))
--#endif
    self.app:yield_delay_s(1.0)
    self.hit_feedback_label = nil
  end
end

function fight_manager:start_victory(some_fighter)
  if some_fighter.fighter_progression.character_type == character_types.pc then
    log("player wins", 'itest')
    self.won_last_fight = true
  else  -- some_fighter.fighter_progression.character_type == character_types.npc
    log("ai wins", 'itest')
    self.won_last_fight = false
  end

  self:stop_fight()  -- characters remember quotes here
  self.app.managers[':adventure'].next_step = 'floor_loop'
  flow:query_gamestate_type(':adventure')
end

-- ui

-- update (for render)

function fight_manager:update_fighters()
  for fighter in all(self.fighters) do
    fighter:update()
  end
end

-- render

function fight_manager:draw_fighters()
  for fighter in all(self.fighters) do
    fighter:draw()
  end
end

function fight_manager:draw_hud()
  -- don't draw health bars here, they are now part of fighters draw

  if self.hit_feedback_label then
    self.hit_feedback_label:draw()
  end
end

return fight_manager
