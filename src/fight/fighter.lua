require("engine/core/class")
require("engine/core/math")
local ui = require("engine/ui/ui")

local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

local fighter = new_class()

--[[
Parameters
  character: character                      character associated to this fighter
  fighter_progression: fighter_progression  progression status of this fighter

State
  hp: int                                   current hp
  is_attacker: bool                         true iff fighter attacks this turn
  last_quote: quote_info?                   last quote said, if any
  received_attack_id_count_map: {int: int}  count of new attacks received during current fight,
                                            indexed by attack id (to measure exposure)
  received_reply_id_count_map: {int: int}   count of new replies received during current fight,
                                            indexed by attack id (to measure exposure)
  available_attack_ids: {int}               sequence of attacks that can still be used in this fight
  available_reply_ids: {int}                sequence of replies that can still be used in this fight
                                            because normal replies are not consumed like attacks, this is almost
                                            the same as the fighter progression known_reply_ids,
                                            but not exactly (e.g. the cancel reply should be consumed,
                                            and we may add dummies)
  has_just_skipped: bool                    true iff this fighter has said the "skip" attack last turn
                                            cleared as soon as this fighter becomes active again
--]]
function fighter:_init(char, fighter_prog)
--#if assert
  assert(fighter_prog.fighter_info.character_info_id, char.character_info.id,
    "fighter_prog.fighter_info.character_info_id ("..fighter_prog.fighter_info.character_info_id..
    ") != char.character_info.id ("..char.character_info.id..")")
--#endif

  self.character = char
  self.fighter_progression = fighter_prog

  -- fighter status
  self.hp = fighter_prog.max_hp
  self.last_quote = nil
  self.received_attack_id_count_map = {}
  self.received_reply_id_count_map = {}
  self.available_attack_ids = copy_seq(fighter_prog.known_attack_ids)
  self.available_reply_ids = copy_seq(fighter_prog.known_reply_ids)
  self.has_just_skipped = false
end

--#if log
function fighter:_tostring()
  return "[fighter("..dump(self.character.character_info.name)..", hp="..tostr(self.hp)..")]"
end
--#endif

function fighter:get_name()
  return self.character.character_info.name
end

-- logic

function fighter:get_available_quote_ids(quote_type)
  if quote_type == quote_types.attack then
    return self.available_attack_ids
  else  -- quote_type == quote_types.reply
    return self.available_reply_ids
  end
end

-- Return an attack quote following the policy:
-- NPC
--   - pick a random attack from the available ids
-- PC
--   - try to pick a random attack for which no reply is known yet
--   - if replies are known for all available attacks,
--       pick a random attack from the available ids

-- Note: because we don't track PC memory, we don't know if the PC
--   is supposed to know if his opponent knows the reply to his attacks, and which ones, yet.
-- Therefore, we cannot have the PC select attacks have not been counted by the
--   opponent yet, not pick the skip attack when all the attacks are known to be counterable.
-- This must be taken into account when running balance itests.

-- Humans can call this method so we can itest easily with AI controlling PC.
-- AI fallback to losing attack if no attack is available
--   but human should have skipped his turn on caller side,
--   so assert if there are no attacks available for him
function fighter:auto_pick_attack()
  -- copy is not needed since even an added losing attack will be removed from the
  --   available attacks after usage, but cleaner
  local available_attack_ids = copy_seq(self:get_available_quote_ids(quote_types.attack))

--#if assert
  assert(#available_attack_ids > 0, "auto_pick_attack should only be called when at least one attack is available."..
      "if no attack is left, request_human/ai_fighter_action should add a dummy quote as fallback")
--#endif

  -- note: if no attack was left, we've added losing attack (-1) in request_human/ai_fighter_action,
  --   and we know that we will return the losing attack

  local random_attack_id

  if self.fighter_progression.character_type == character_types.pc then
    -- DEBUG for itests: when human auto-picks an attack, try (available) attacks for which replies
    --   are not known first, as a player would do to learn counters faster
    local unmatched_attack_ids = filter(self.available_attack_ids, function (attack_id)
      -- fighter is only interested in known replies in general, not just replies available right now
      for reply_id in all(self.fighter_progression.known_reply_ids) do
        if gameplay_data:get_quote_match_with_id(attack_id, reply_id) then
          -- fighter already knows a reply for this attack, skip it
          return false
        end
      end
      -- no matching reply known, so this attack is unmatched
      return true
    end)

    if #unmatched_attack_ids > 0 then
      random_attack_id = pick_random(unmatched_attack_ids)
      log("fighter \""..self:get_name().."\" picks unmatched attack ("..random_attack_id..")", 'fight')
    else
      -- all attacks have known replies and and we are not sure if there are *better* replies to learn
      --   (more exactly the player is not supposed to know), so just use a random attack
      random_attack_id = pick_random(available_attack_ids)
      log("fighter \""..self:get_name().."\" picks random attack ("..random_attack_id..")", 'fight')
    end
  else
    -- for attack, ai picks random one among available (sequence is never empty here)
    random_attack_id = pick_random(available_attack_ids)
      log("fighter \""..self:get_name().."\" picks random attack ("..random_attack_id..")", 'fight')
  end

  return gameplay_data:get_quote(quote_types.attack, random_attack_id)
end

-- Return a reply following the policy:
-- - return any matching reply for the passed attack id, if possible
-- - else, return a losing reply
-- Humans can call this method so we can itest easily with AI controlling PC.
-- Both AI and human fallback to losing reply if no reply is available
function fighter:auto_pick_reply(attack_id)
  assert(attack_id >= 0, "skip attack should be resolved immediately, so auto_pick_reply should not be called")

  local picked_reply_id

  local available_reply_ids = copy_seq(self:get_available_quote_ids(quote_types.reply))

  --#if assert
  assert(#available_reply_ids > 0, "auto_pick_reply should only be called when at least one reply is available."..
      "if no reply is left, request_human/ai_fighter_action should add a dummy quote as fallback")
  --#endif

  -- pick matching reply if possible
  -- v2: pick random reply among matching replies (whatever their power is)
  -- note: if no reply was left, we've added losing reply (-1) in request_human/ai_fighter_action,
  --   and we know that we will return the losing reply
  local candidate_replies = filter(available_reply_ids, function (reply_id)
    local quote_match = gameplay_data:get_quote_match_with_id(attack_id, reply_id)
    return quote_match ~= nil  -- power = 0 (cancel reply) is a valid candidate
  end)

  if #candidate_replies > 0 then
    picked_reply_id = pick_random(candidate_replies)
    log("fighter \""..self:get_name().."\" picks randomly matching reply ("..picked_reply_id..")", 'fight')
  else
    if gameplay_data.npc_random_reply_fallback then
      -- no matching quote found; pick a random reply instead (it will lose, but may teach a new reply
      --   to the player as an extra)
      picked_reply_id = pick_random(available_reply_ids)
      log("fighter \""..self:get_name().."\" picks cannot find match => picks randomly reply ("..picked_reply_id..")", 'fight')
    else
      -- no matching quote found; pick a losing reply instead
      -- this includes the case where there is only the losing reply as fallback
      --   (in which case available_reply_ids is {-1})
      picked_reply_id = -1
      log("fighter \""..self:get_name().."\" picks losing reply (-1) (none matching)", 'fight')
    end
  end

  local picked_reply = gameplay_data:get_quote(quote_types.reply, picked_reply_id)
  return picked_reply
end

function fighter:preview_quote(quote)
  local is_attacking = quote.type == quote_types.attack
  self.character.speaker:think(quote.text, false, is_attacking)
end

function fighter:say_quote(quote)
  local is_attacking = quote.type == quote_types.attack

  self.character.speaker:say(quote.text, false, is_attacking)
  self.last_quote = quote

  if is_attacking then
    -- attack: remove it from available sequence for this fight
    del(self.available_attack_ids, quote.id)
  elseif gameplay_data.consume_reply then
    -- reply: remove it from available sequence for this fight, if experimental rule flag is set
    del(self.available_reply_ids, quote.id)
  end
end

function fighter:take_damage(damage)
  self.hp = self.hp - damage
  log("fighter '"..self:get_name().."' takes "..damage.." damage! => "..self.hp.." HP", 'fight')
  if self.hp <= 0 then
    log("fighter '"..self:get_name().."' dies!", 'fight')
    self.hp = 0
  end
end

function fighter:is_alive()
  return self.hp > 0
end

-- learning

function fighter:on_receive_quote(quote)
  -- Battle rules v2: AI don't learn anymore
  -- This means that learning is only for PC, and always instant since he's level 10
  -- but we keep the reception count logic in case we want to re-enable progressive learning
  -- (for either PC or NPC) later.
  if self.fighter_progression.character_type == character_types.npc then
    return
  end

  -- Upon receiving an attack or reply the fighter doesn't know,
  --   he/she buffers it with a reception count.
  -- When the count has reached the required learning level threshold,
  --   the fighter automatically learns it at the end of the fight.
  -- This applies even if the quote was deadly.
  local known_quote_ids
  local received_quote_id_count_map

  if quote.type == quote_types.attack then
    known_quote_ids = self.fighter_progression.known_attack_ids
    received_quote_id_count_map = self.received_attack_id_count_map
  else  -- quote.type == quote_types.reply
    known_quote_ids = self.fighter_progression.known_reply_ids
    received_quote_id_count_map = self.received_reply_id_count_map
  end

  -- check if quote can be learned (must be new, and not losing quote;
  --   cancel reply can be learned, although logic is special, as AI cannot
  --   learn the cancel quote match and will only use it in special circumstances)
  local can_learn = not contains(known_quote_ids, quote.id) and quote.id >= 0 and
    quote.level <= self.fighter_progression.level
  if can_learn then
    local reception_count = received_quote_id_count_map[quote.id]
    -- reception count starts nil then immediately increments to 1,
    --   so it's never 0 and we can check for nil directly
    if reception_count then
      received_quote_id_count_map[quote.id] = reception_count + 1
    else
      received_quote_id_count_map[quote.id] = 1
    end
  end
end

function fighter:on_witness_quote_match(quote_match)
  -- Upon witnessing a quote match (as attacker or replier),
  --   fighter *immediately* tries to learn the match
  --   (used by PC only, see try_learn_quote_match)
  self.fighter_progression:try_learn_quote_match(quote_match.id)
end

function fighter:update_learned_quotes()
  -- Transfer quotes received during this fight to the progression count
  -- This allows the fighter to learn a high-level quotes across multiple
  --   fights, without forgetting the various occurrences between each.
  -- This will clear the passed maps
  self.fighter_progression:transfer_received_attack_id_count_map(self.received_attack_id_count_map)
  self.fighter_progression:transfer_received_reply_id_count_map(self.received_reply_id_count_map)
end

-- update (for render)

function fighter:update()
  self.character:update()
end

-- render

function fighter:draw()
  self.character:draw()
  self:draw_health_bar()
  self:draw_name_label()
end

function fighter:draw_health_bar()
  local center_x_offset = visual_data.health_bar_center_x_dist_from_char

  -- health bar is behind character
  if self.character.direction == horizontal_dirs.right  then
    center_x_offset = - center_x_offset
  end

  local center_x = self.character.root_pos.x + center_x_offset
  local left = center_x - visual_data.health_bar_half_width
  local right = center_x + visual_data.health_bar_half_width
  local top = self.character.root_pos.y + visual_data.health_bar_top_from_char
  local bottom = self.character.root_pos.y + visual_data.health_bar_bottom_from_char
  local hp_ratio = self.hp / self.fighter_progression.max_hp
  ui.draw_gauge(left, top, right, bottom, hp_ratio, directions.up, colors.dark_blue, colors.white, colors.blue)
end

function fighter:draw_name_label()
  local text = self:get_name()
  local text_width, text_height = compute_size(text)
  local label_width, label_height = text_width + 1, text_height + 1

  local center_x_offset = visual_data.fighter_name_label_center_offset_x
  if self.character.direction == horizontal_dirs.left  then
    center_x_offset = - center_x_offset
  end
  local center_x = self.character.root_pos.x + center_x_offset
  local center_y = self.character.root_pos.y + visual_data.fighter_name_label_center_offset_y
  local box_left = flr(center_x - label_width / 2)
  local box_right = ceil(center_x + label_width / 2)
  local box_top = flr(center_y - label_height / 2)
  local box_bottom = ceil(center_y + label_height / 2)
  ui.draw_rounded_box(box_left, box_top, box_right, box_bottom, colors.black, colors.white)
  ui.print_centered(text, center_x, center_y, colors.black)
end

return fighter
