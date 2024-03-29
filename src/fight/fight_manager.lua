local flow = require("engine/application/flow")
local manager = require("engine/application/manager")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local quote_info = require("content/quote_info")
local fighter = require("fight/fighter")
local localizer = require("localization/localizer")
local menu_helper = require("menu/menu_helper")
local menu_item = require("menu/menu_item")
local audio_data = require("resources/audio_data")
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
function fight_manager:init()
  manager.init(self)

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

--#if cheat
  if input:is_just_pressed(button_ids.x) then
    if input:is_down(button_ids.left) then
      -- insta-suicide
      self:insta_kill(1)
    else
      -- insta-kill
      self:insta_kill(2)
    end
  end
--#endif
end

--#if cheat
function fight_manager:insta_kill(fighter_index)
  if self.fighters[fighter_index].hp > 0 then
    log("insta-kill fighter "..fighter_index, 'fight')

    -- clear any coroutines to avoid conflict with running animations and sequences about to prompt quotes
    self.app:stop_all_coroutines()

    -- clear any remaining hud (access supposedly private members until we have better interface)
    local dm = self.app.managers[':dialogue']
    if dm and dm.text_menu then
      dm.text_menu.active = false
    end

    -- insta-kill target
    self.fighters[fighter_index]:take_damage(10)
    self:check_exchange_result(self.fighters[1], self.fighters[2])
  end
end
--#endif

function fight_manager:render()  -- override
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
  self.fighters[self.active_fighter_index].has_just_skipped = false
end

function fight_manager:is_active_fighter_attacking()
  return self:get_active_fighter_opponent().last_quote == nil
end

-- flow

function fight_manager:pick_matching_random_npc_fighter_prog()
  local candidate_npc_fighter_prog_s = self.app.game_session:get_all_candidate_npc_fighter_prog()
  assert(#candidate_npc_fighter_prog_s > 0, "no candidate npc found at floor "..self.app.game_session.floor_number)
  return rnd(candidate_npc_fighter_prog_s)
end

function fight_manager:start_fight_with_next_opponent()
  assert(self.next_opponent, "fight_manager:start_fight_with_next_opponent: next opponent not set")
  self:start_fight_with(self.next_opponent)
  -- do not consume next_opponent now, it will be checked at the beginning of
  --   adventure_state:_play_floor_loop as the previous opponent
end

function fight_manager:start_fight_with(opponent_fighter_prog)
  -- track last opponent
  self.app.game_session.last_opponent = opponent_fighter_prog

  -- audio: start bgm
  music(opponent_fighter_prog.fighter_info.fight_bgm)

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

  log("loaded fighters: "..pc_fighter:get_name().." vs "..npc_fighter:get_name(), 'fight')
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
  local temp_available_quote_ids = copy_seq(human_fighter:get_available_quote_ids(quote_type))

  -- for debugging, allow ai control over pc
  if human_fighter.fighter_progression.control_type == control_types.human then
    if quote_type == quote_types.attack then
      -- PC (with human control) can voluntarily skip turn when attacking, unless the opponent
      --   has just skipped (voluntarily or not) => voluntary stale prevention
      -- if PC has no attacks left, he can only skip (as with replies)
      if not self:get_active_fighter_opponent().has_just_skipped or #temp_available_quote_ids == 0 then
        add(temp_available_quote_ids, -1)
      end
    elseif #temp_available_quote_ids == 0 then
      -- no replies left, add losing reply
      -- (unlike attacks, only allow this when no replies are left, since it is never advantageous
      --  not to try something to reply)
      add(temp_available_quote_ids, -1)
    end

    local items = self:generate_quote_menu_items(human_fighter, quote_type, temp_available_quote_ids)
    self.app.managers[':dialogue']:prompt_items(items)
  else  -- control_types.ai
    -- DEBUG for itests: human can be under AI control

    local next_quote

    if #temp_available_quote_ids > 0 then
      -- pick quote like an ai
      next_quote = self:auto_pick_quote(human_fighter, quote_type)
    else
      -- no quotes left
      -- pc has nothing to say, whether attack or reply, auto-select skip attack/losing reply
      -- (pc as ai can only skip when no attacks are left)
      next_quote = gameplay_data:get_quote(quote_type, -1)
    end

    self:wait_and_do(visual_data.ai_say_quote_delay, self.say_quote, self, human_fighter, next_quote)
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
    local select_quote_callback = function ()
      self:preview_quote(human_fighter, quote)
    end

    -- menu item prefixes choices with "> " (or blank with width of 2 chars)
    --   so we need to subtract 2 from the usually available string length
    local quote_string = localizer:get_string(quote.localized_string_id)
    local clamped_text = menu_helper.clamp_text_with_ellipsis(quote_string, visual_data.bottom_box_max_chars_per_line - 2)
    return menu_item(clamped_text, say_quote_callback, select_quote_callback)
  end)
end

function fight_manager:request_ai_fighter_action(ai_fighter)
  assert(self.fighters[self.active_fighter_index] == ai_fighter)
  assert(ai_fighter.fighter_progression.character_type == character_types.npc)

  local quote_type = self:is_active_fighter_attacking() and quote_types.attack or quote_types.reply
  local available_quote_ids = ai_fighter:get_available_quote_ids(quote_type)

  local next_quote

  if #available_quote_ids > 0 then
    -- npc always use ai control (we cannot plug human input into npc decisions currently)
    next_quote = self:auto_pick_quote(ai_fighter, quote_type)
  else
    -- no quotes left
    -- npc has nothing to say, whether attack or reply, auto-select skip attack/losing reply
    -- (pc as ai can only skip when no attacks are left)
    next_quote = gameplay_data:get_quote(quote_type, -1)
  end

  self:wait_and_do(visual_data.ai_say_quote_delay, self.say_quote, self, ai_fighter, next_quote)
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

function fight_manager:preview_quote(active_fighter, quote)
  active_fighter:preview_quote(quote)
end

function fight_manager:say_quote(active_fighter, quote)
  local is_attacking = quote.type == quote_types.attack

  -- don't wait for input, since either the quote menu (pc replying), the auto play (npc replying),
  --   or the quote match resolution (if saying a reply) will hide that text eventually
--#if log
  local verb = is_attacking and "attacks" or "replies"
  local quote_string = localizer:get_string(quote.localized_string_id)
  log("fighter '"..active_fighter:get_name().."' "..verb..": ("..quote.id..") \""..quote_string.."\"", 'fight')
--#endif
  active_fighter:say_quote(quote)  -- will set its last_quote

  if is_attacking then
    if quote.id == -1 then
      -- active fighter said "skip" attack, no need to ask opponent for reply
      -- wait just enough to show the text bubble, and skip turn
      self:wait_and_do(visual_data.resolve_skip_turn_delay,
        self.resolve_skip_attack, self, active_fighter)
    else
      -- learning: replier receives quote and may remember it for later
      self:get_active_fighter_opponent():on_receive_quote(quote)

      -- normal quote was said
      self:wait_and_do(visual_data.request_reply_delay,
        self.request_next_fighter_action, self)
    end
  else  -- not is_attacking
    -- learning: attacker receives quote and may remember it for later
    self:get_active_fighter_opponent():on_receive_quote(quote)

    -- last quote of opponent should be attack, and active fighter has replied
    self:wait_and_do(visual_data.resolve_exchange_delay,
      self.resolve_exchange, self, self:get_active_fighter_opponent(), active_fighter)
  end
end

function fight_manager:request_next_fighter_action()
  self:give_control_to_next_fighter()
  self:request_active_fighter_action()
end


function fight_manager:resolve_skip_attack(active_fighter)
  -- consume quote now to prevent opponent from trying to reply,
  --   have fighter stop speaking and request next turn
  active_fighter.has_just_skipped = true
  active_fighter.last_quote = nil
  active_fighter.character.speaker:stop()

  -- to avoid loophole where both fighters have nothing to say and get stuck,
  --   on the 2nd skip attack, end battle on stale
  -- fighter with more hp is winner
  -- in case of draw, the active fighter wins
  -- Note: voluntary skip does *not* end the game, so in theory, 2 human fighters could provoke
  --   a stale on purpose to avoid losing. This never happens because we play PvE only,
  --   but if we had to solve this, I would simply make voluntary skip an available attack
  --   and consume it like the others (could also be done to avoid spamming skip anyway).
  local opponent = self:get_active_fighter_opponent()
  if opponent.has_just_skipped then
    -- the test below is needed even though PC cannot skip voluntarily after the opponent has just skipped,
    --   because the reverse may happen: PC skips voluntarily, then opponent *must* skip
    -- in this case, PC cannot skip again next turn so there is no reason to declare stale
    if #active_fighter.available_attack_ids == 0 and #opponent.available_attack_ids == 0 then
      local winner
      if active_fighter.hp >= opponent.hp then
        winner = active_fighter
      else
        winner = opponent
      end
      self.app:start_coroutine(self.async_start_victory_by_stale, self, winner)
      return
    end
  end

  self:wait_and_do(visual_data.skip_turn_delay,
    self.request_next_fighter_action, self)
end

-- attacker: fighter
-- replier: fighter
function fight_manager:resolve_exchange(attacker, replier)
  local attacker_quote = attacker.last_quote
  local replier_quote = replier.last_quote

  assert(attacker_quote.type == quote_types.attack)
  assert(replier_quote.type == quote_types.reply)

  local quote_match = gameplay_data:get_quote_match(attacker_quote, replier_quote)

  -- cancel_quote_match is used to cancel an attack, and has a power of 0
  -- a nil quote_match, however, means the reply failed completely; so check for nil first
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

  self:wait_and_do(visual_data.check_exchange_result_delay,
    self.check_exchange_result, self, attacker, replier)
end

function fight_manager:check_exchange_result(attacker, replier)
  self:clear_exchange()

  local is_attacker_alive = attacker:is_alive()
  local is_replier_alive = replier:is_alive()
  if is_attacker_alive and is_replier_alive then
    -- in our rules, replying fighter keeps control whatever the result of the exchange,
    --   but becomes attacker, so just continue to next action
    local active_fighter = self.fighters[self.active_fighter_index]
    if active_fighter == attacker then
      -- attacker ended this turn, must be a losing attack
      -- passive replier should now play
      self:give_control_to_next_fighter()
    else
      assert(active_fighter == replier)
      -- replier ended this turn as in a usual exchange
      -- replier should play again, so don't change active fighter
    end

    -- now wait to request action for appropriate fighter
    self:wait_and_do(visual_data.request_action_after_exchange_delay,
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
  self.app:start_coroutine(self.async_play_hurt_anim, self, target_fighter.character)

  -- fx
  local hit_fx_offset = visual_data.hit_fx_offset_right:copy()
  if target_fighter.direction == horizontal_dirs.left then
    hit_fx_offset:mirror_x()
  end
  -- use root_pos not sprite_pos, as the latter may change during async_play_hurt_anim
  self.hit_fx_pos = target_fighter.character.root_pos + hit_fx_offset
  self.hit_fx:play("once")

  -- feedback message
  self.app:start_coroutine(self.async_show_hit_feedback_label, self, target_fighter, quote_type, damage)

  -- audio
  sfx(audio_data.sfx.fight_direct_hit)
end

function fight_manager:play_neutralize_feedback(target_fighter)
  -- feedback message
  self.app:start_coroutine(self.async_show_hit_feedback_label, self, target_fighter, quote_types.reply, 0)
end

function fight_manager:async_play_hurt_anim(fighter_character)
  local offset = visual_data.hurt_sprite_offset_right:copy()
  if fighter_character.direction == horizontal_dirs.left then
    offset:mirror_x()
  end
  -- original value was fighter_character.root_pos, so just add offset
  fighter_character.sprite_pos:add_inplace(offset)
  fighter_character.sprite:play("hurt")
  self.app:yield_delay_s(0.5)
  fighter_character.sprite_pos:copy_assign(fighter_character.root_pos)
  fighter_character.sprite:play("idle")
end

function fight_manager:async_show_hit_feedback_label(target_fighter, quote_type, damage)
  local repr_damage = min(damage, 3)
  self.hit_feedback_label = visual_data.hit_feedback_labels[target_fighter.fighter_progression.character_type][quote_type][repr_damage]
--#if assert
--#if tostring
  -- note that assert => log so joinstr should be defined
  assert(self.hit_feedback_label, "no hit feedback label for (character type, quote type, representative damage): "..
    joinstr(", ", target_fighter.fighter_progression.character_type, quote_type, repr_damage))
--#endif
--#endif
  self.app:yield_delay_s(1.0)
  self.hit_feedback_label = nil
end

function fight_manager:async_start_victory_by_stale(some_fighter)
  self.app:yield_delay_s(visual_data.start_victory_by_stale_delay)
  some_fighter.character.speaker:say_and_wait_for_input("stale, uh? i have more hp, so i win!", true)
  self:start_victory(some_fighter)
end

function fight_manager:start_victory(some_fighter)
  if some_fighter.fighter_progression.character_type == character_types.pc then
    log("player WINS", 'fight')
    self.won_last_fight = true

    -- audio: stop bgm, play victory jingle
    music(-1)
    sfx(audio_data.jingle.fight_victory)

    self:wait_and_do(visual_data.victory_anim_duration,
      self.stop_fight_and_return_to_adv, self)
  else  -- some_fighter.fighter_progression.character_type == character_types.npc
    log("npc '"..some_fighter.character.character_info.name.."' WINS", 'fight')
    self.won_last_fight = false

    -- audio: stop bgm
    music(-1)

    self:wait_and_do(visual_data.defeat_anim_duration,
      self.stop_fight_and_return_to_adv, self)
  end
end

function fight_manager:stop_fight_and_return_to_adv()
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


-- coroutine helper (used to be in engine, but extracted as other projects didn't need it)

-- nice, but to avoid lamdba prefer a generic function that takes a callback
-- as parameter itself as coroutine curry param

-- start a coroutine that waits N seconds and apply callback with variadic args
-- ! for methods, remember to pass the instance it*self* as first optional argument !
function fight_manager:wait_and_do(delay_s, callback, ...)
  self.app:start_coroutine(function (delay_s, ...)
    self.app:yield_delay_s(delay_s)
    callback(...)
  end, delay_s, ...)
end


return fight_manager
