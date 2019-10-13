local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local floor_info = require("content/floor_info")
local quote_info = require("content/quote_info")
local quote_match_info = require("content/quote_match_info")

local attacks = {
  quote_info( 1, quote_types.attack, 1, "attack 1!"),
  quote_info( 2, quote_types.attack, 1, "attack 2!"),
  quote_info( 3, quote_types.attack, 1, "attack 3!"),
  quote_info( 4, quote_types.attack, 2, "attack 4!"),
  quote_info( 5, quote_types.attack, 2, "attack 5!"),
  quote_info( 6, quote_types.attack, 3, "attack 6!"),
  quote_info( 7, quote_types.attack, 3, "attack 7!"),
  quote_info( 8, quote_types.attack, 3, "attack 8!"),
  quote_info( 9, quote_types.attack, 4, "attack 9!"),
  quote_info(10, quote_types.attack, 4, "attack 10!"),
  quote_info(11, quote_types.attack, 5, "attack 11!"),
  quote_info(12, quote_types.attack, 5, "1234567890123456789012345678! 1234567890123456789012345678!"),
  quote_info(13, quote_types.attack, 5, "attack 13!"),
  quote_info(14, quote_types.attack, 6, "attack 14!"),
  quote_info(15, quote_types.attack, 6, "attack 15!"),
}

local replies = {
  quote_info( 1, quote_types.reply,  1, "reply 1!"),
  quote_info( 2, quote_types.reply,  1, "reply 2!"),
  quote_info( 3, quote_types.reply,  1, "reply 3!"),
  quote_info( 4, quote_types.reply,  2, "reply 4!"),
  quote_info( 5, quote_types.reply,  2, "reply 5!"),
  quote_info( 6, quote_types.reply,  3, "reply 6!"),
  quote_info( 7, quote_types.reply,  3, "reply 7!"),
  quote_info( 8, quote_types.reply,  3, "reply 8!"),
  quote_info( 9, quote_types.reply,  4, "reply 9!"),
  quote_info(10, quote_types.reply,  4, "reply 10!"),
  quote_info(11, quote_types.reply,  5, "reply 11!"),
  quote_info(12, quote_types.reply,  5, "reply 12!"),
  quote_info(13, quote_types.reply,  5, "reply 13!"),
  quote_info(14, quote_types.reply,  6, "reply 14!"),
  quote_info(15, quote_types.reply,  6, "reply 15!"),
}

local quote_matches = {
  quote_match_info(1, 1),
  quote_match_info(2, 2),
  quote_match_info(3, 3),
  quote_match_info(4, 4),
  quote_match_info(5, 5),
  quote_match_info(6, 6),
  quote_match_info(7, 7),
}

local floors = {
  floor_info( 1,  1,  1),
  floor_info( 2,  1,  2),
  floor_info( 3,  2,  2),
  floor_info( 4,  2,  3),
  floor_info( 5,  3,  3),
  floor_info( 6,  3,  4),
  floor_info( 7,  4,  4),
  floor_info( 8,  4,  5),
  floor_info( 9,  5,  5),
  floor_info(10,  6,  6),
}

-- character story and visual info
local pc_info = character_info(0, "you", 0)
local npc_info_s = {
  character_info(1, "intern designer", ),
  character_info(2, "intern programmer", ),
  character_info(3, "intern qa", ),
  character_info(4, "intern marketing", ),
  character_info(5, "placement designer", ),
  character_info(6, "placement programmer", ),
  character_info(7, "placement qa", ),
  character_info(8, "placement marketing", ),
  character_info(9, "junior designer", ),
  character_info(10, "junior programmer", ),
  character_info(11, "junior qa", ),
  character_info(12, "junior marketing", ),
  character_info(13, "designer", ),
  character_info(14, "programmer", ),
  character_info(15, "manager", ),
  character_info(16, "legal advisor", ),
  character_info(17, "senior designer", ),
  character_info(18, "senior programmer", ),
  character_info(19, "senior qa", ),
  character_info(20, "senior marketing", ),
}

-- fighters are mostly mapped to characters 1:1, but storing characters separately is useful
--   in case we have a non-fighting npc
local pc_fighter_info = fighter_info(0, 0, 1, 3, {1, 2})
local npc_fighter_info_s = {
  fighter_info( 1,  1, 1, 3, {1, 2}. {}, {}),
  fighter_info( 2,  2, 1, 3, {2, 3}, {}, {}),
  fighter_info( 3,  3, 1, 3, {1, 3}, {}, {}),
  fighter_info( 4,  4, 1, 3, {1, 2, 3}, {}, {}),
  fighter_info( 5,  5, 2, 3, {1, 4}, {}, {}),
  fighter_info( 6,  6, 2, 3, {2, 5}, {}, {}),
  fighter_info( 7,  7, 2, 3, {3, 4}, {}, {}),
  fighter_info( 8,  8, 2, 3, {4, 5}, {}, {}),
  fighter_info( 9,  9, 3, 3, {3, 6}, {}, {}),
  fighter_info(10, 10, 3, 3, {4, 7}, {}, {}),
  fighter_info(11, 11, 3, 3, {5, 8}, {}, {}),
  fighter_info(12, 12, 3, 3, {4, 5, 8}, {}, {}),
  fighter_info(13, 13, 4, 3, {7, 10}, {}, {}),
  fighter_info(14, 14, 4, 3, {1}, {}, {}),
  fighter_info(15, 15, 4, 3, {1}, {}, {}),
  fighter_info(16, 16, 4, 3, {1}, {}, {}),
  fighter_info(17, 17, 5, 3, {1}, {}, {}),
  fighter_info(18, 18, 5, 3, {1}, {}, {}),
  fighter_info(19, 19, 5, 3, {1}, {}, {}),
  fighter_info(20, 20, 5, 3, {1}, {}, {}),
}

local gameplay_data = {
  attacks = attacks,
  replies = replies,
  quote_matches = quote_matches,
  floors = floors,
  pc_info = pc_info,
  npc_info_s = npc_info_s,
  pc_fighter_info = pc_fighter_info,
  npc_fighter_info_s = npc_fighter_info_s,

  -- misc gameplay parameters
  fighter_max_hp = 3
}

-- data access helpers

function gameplay_data:are_quote_matching(attack_info, reply_info)
  -- quote_match is a struct, so == is equality member, so we can check
  --  if the wanted match exists directly with contain
  return contains(quote_matches, quote_match_info(attack_info.id, reply_info.id))
end

function gameplay_data:get_floor_info(floor_number)
  return self.floors[floor_number]
end

function gameplay_data:get_fighter_info_table_with_level(level)
  return filter(self.fighter_info_s, function (fighter_info)
    return fighter_info.level == level
  end)
end

return gameplay_data
