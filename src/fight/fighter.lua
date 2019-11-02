require("engine/core/class")
require("engine/core/math")
local ui = require("engine/ui/ui")

local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

local fighter = new_class()

--[[
Parameters
  character_type: character_types  is the fighter controlled by the player or some ai?
  npc: npc?                        if character_type is ai, npc instance that spawned this fighter
                                   else, nil
  max_hp: int                      initial hp
  sprite: sprite_data              sprite to render
  pos: vector                      position on screen
  direction: horizontal_dirs       facing left or right?

State
  hp: int                                   current hp
  is_attacker: bool                         true iff fighter attacks this turn
  last_quote: (quote_info|nil)              last quote said, if any
  received_attack_id_count_map: {int: int}  count of new attacks received during current fight,
                                            indexed by attack id (to measure exposure)
  received_reply_id_count_map: {int: int}   count of new replies received during current fight,
                                            indexed by attack id (to measure exposure)
  available_attack_ids: {int}               sequence of attacks that can still be used in this fight
  available_reply_ids: {int}                sequence of replies that can still be used in this fight
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
--   pick a random one from the available ids
-- Humans can call this method so we can itest easily with AI controlling PC.
-- AI fallback to losing attack if no attack is available
--   but human should have skipped his turn on caller side,
--   so assert if there are no attacks available for him
function fighter:auto_pick_attack()
  -- copy is not needed since even an added losing attack will be removed from the
  --   available attacks after usage, but cleaner
  local available_attack_ids = copy_seq(self:get_available_quote_ids(quote_types.attack))

  if #available_attack_ids == 0 then
--#if assert
    assert(self.fighter_progression.character_type == character_types.npc, "only npc are forced to say losing attack when none is left. "..
      "pc should skip their turn, so you should never call auto_pick_attack in that case, even in debug.")
--#endif
    -- ai has nothing to say, whether attack or reply, add losing attack
    add(available_attack_ids, -1)
  end

  -- for attack, ai picks random one among available (sequence is never empty here)
  local random_attack_id = pick_random(available_attack_ids)
  return gameplay_data:get_quote(quote_types.attack, random_attack_id)
end

-- Return a reply following the policy:
-- - return any matching reply for the passed attack id, if possible
-- - else, return a random reply
-- Humans can call this method so we can itest easily with AI controlling PC.
-- Both AI and human fallback to losing reply if no reply is available
function fighter:auto_pick_reply(attack_id)
  local available_reply_ids = copy_seq(self:get_available_quote_ids(quote_types.reply))

  if #available_reply_ids == 0 then
    add(available_reply_ids, -1)
  end

  local reply = nil

  -- pick matching reply if possible
  -- v1: just pick first working match, ignoring power
  for quote_match_id in all(self.fighter_progression.known_quote_match_ids) do
    local quote_match = gameplay_data.quote_matches[quote_match_id]
    if quote_match.attack_id == attack_id then
      -- found a match, but it must also know the reply itself (it may be still in learning phase)
      if contains(available_reply_ids, quote_match.reply_id) then
        reply = gameplay_data:get_quote(quote_types.reply, quote_match.reply_id)
        log("fighter \""..self:get_name().."\" found matching reply ("..reply.id..")", 'itest')
      else
--#if log
        log("fighter \""..self:get_name().."\" knowns about matching reply "..quote_match.reply_id..
          " \""..gameplay_data:get_quote(quote_types.reply, quote_match.reply_id).text.."\" but hasn't finished learning it", 'itest')
--#endif
      end
    end
  end

  if not reply then
    -- no matching quote found; pick a random reply instead
    -- remember we added a dummy quote above if needed, so sequence is never empty
    local random_reply_id = pick_random(available_reply_ids)
    reply = gameplay_data:get_quote(quote_type, random_reply_id)
    log("fighter \""..self:get_name().."\" picks randomly reply ("..random_reply_id..")", 'itest')
  end

  return reply
end

function fighter:say_quote(quote)
  local is_attacking = quote.type == quote_types.attack

  self.character.speaker:say(quote.text, false, is_attacking)
  self.last_quote = quote

  -- if an attack, remove it from available sequence for this fight
  if is_attacking then
    del(self.available_attack_ids, quote.id)
  end
end

function fighter:take_damage(damage)
  self.hp = self.hp - damage
  log("fighter '"..self:get_name().."' takes "..damage.." damage! => "..self.hp.." HP", "itest")
  if self.hp <= 0 then
    log("fighter '"..self:get_name().."' dies!", "itest")
    self.hp = 0
  end
end

function fighter:is_alive()
  return self.hp > 0
end

-- learning

function fighter:on_receive_quote(quote)
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
  --   fighter *immediately* learns the match.
  -- This allows for reactive fights where known replies can be reused in
  --   different ways, learning from your opponent.
  -- By the way, soon, replies will also be learned immediately
  --   so we can do that for new replies too.
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

-- render

function fighter:draw()
  self.character:draw(self.pos)
  self:draw_health_bar()
  self:draw_name_label()
end

function fighter:draw_health_bar()
  local center_x_offset = visual_data.health_bar_center_x_dist_from_char

  -- health bar is behind character
  if self.character.direction == horizontal_dirs.right  then
    center_x_offset = - center_x_offset
  end

  local center_x = self.character.pos.x + center_x_offset
  local left = center_x - visual_data.health_bar_half_width
  local right = center_x + visual_data.health_bar_half_width
  local top = self.character.pos.y + visual_data.health_bar_top_from_char
  local bottom = self.character.pos.y + visual_data.health_bar_bottom_from_char
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
  local center_x = self.character.pos.x + center_x_offset
  local center_y = self.character.pos.y + visual_data.fighter_name_label_center_offset_y
  local box_left = flr(center_x - label_width / 2)
  local box_right = ceil(center_x + label_width / 2)
  local box_top = flr(center_y - label_height / 2)
  local box_bottom = ceil(center_y + label_height / 2)
  ui.draw_rounded_box(box_left, box_top, box_right, box_bottom, colors.indigo, colors.white)
  ui.print_centered(text, center_x, center_y, colors.black)
end

return fighter
