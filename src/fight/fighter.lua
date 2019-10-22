require("engine/core/class")
require("engine/core/math")
local ui = require("engine/ui/ui")

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
  hp: int                                  current hp
  is_attacker: bool                        true iff fighter attacks this turn
  last_quote: (quote_info|nil)             last quote said, if any
  received_attack_id_count_map: {int: int} count of new attacks received during current fight,
                                           indexed by attack id (to measure exposure)
  received_reply_id_count_map: {int: int}  count of new replies received during current fight,
                                           indexed by attack id (to measure exposure)
--]]
function fighter:_init(char, fighter_prog)
  self.character = char
  self.fighter_progression = fighter_prog

  -- fighter status
  self.hp = fighter_prog.max_hp
  self.last_quote = nil
  self.received_attack_id_count_map = {}
  self.received_reply_id_count_map = {}
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
    -- for now, ignore attacks already used and just return all known attack ids
    return self.fighter_progression.known_attack_ids
  else  -- quote_type == quote_types.reply
    return self.fighter_progression.known_reply_ids
  end
end

function fighter:auto_pick_quote()
  assert(self.character_type == character_types.ai)
  -- todo
end

function fighter:take_damage(damage)
  self.hp = self.hp - damage
  log('fighter "'..self:get_name()..'" takes '..damage..' damage! => '..self.hp..' HP', "itest")
  if self.hp <= 0 then
    log('fighter "'..self:get_name()..'" dies!', "itest")
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
  --   cancel reply can be learned)
  local can_learn = not contains(known_quote_ids, quote.id) and quote.id >= 0
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

  local center_x = self.character.pos.x
  local center_y = self.character.pos.y + visual_data.fighter_name_label_offset_y
  local box_left = flr(center_x - label_width / 2)
  local box_right = ceil(center_x + label_width / 2)
  local box_top = flr(center_y - label_height / 2)
  local box_bottom = ceil(center_y + label_height / 2)
  ui.draw_rounded_box(box_left, box_top, box_right, box_bottom, colors.indigo, colors.white)
  ui.print_centered(text, center_x, center_y, colors.black)
end

return fighter
