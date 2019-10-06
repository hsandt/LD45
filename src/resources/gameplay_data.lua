local floor_info = require("content/floor_info")
local npc_info = require("content/npc_info")
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
  quote_info(12, quote_types.attack, 5, "attack 12!"),
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

-- name npc_info_s (like sequence) to distinguish from a dynamic npc in game session
local npc_info_s = {
  npc_info(1, "intern designer",      1, {1, 2}),
  npc_info(2, "intern programmer",    1, {2, 3}),
  npc_info(3, "intern qa",            1, {1, 3}),
  npc_info(4, "intern marketing",     1, {1, 2, 3}),
  npc_info(5, "placement designer",   2, {1, 4}),
  npc_info(6, "placement programmer", 2, {2, 5}),
  npc_info(7, "placement qa",         2, {3, 4}),
  npc_info(8, "placement marketing",  2, {4, 5}),
  npc_info(9, "junior designer",      3, {3, 6}),
  npc_info(10, "junior programmer",    3, {4, 7}),
  npc_info(11, "junior qa",            3, {5, 8}),
  npc_info(12, "junior marketing",     3, {4, 5, 8}),
  npc_info(13, "designer",             4, {7, 10}),
  npc_info(14, "programmer",           4, {1}),
  npc_info(15, "manager",              4, {1}),
  npc_info(16, "legal advisor",        4, {1}),
  npc_info(17, "senior designer",      5, {1}),
  npc_info(18, "senior programmer",    5, {1}),
  npc_info(19, "senior qa",            5, {1}),
  npc_info(20, "senior marketing",     5, {1}),
}

local gameplay_data = {
  attacks = attacks,
  replies = replies,
  quote_matches = quote_matches,
  floors = floors,
  npcs = npc_info_s
}

-- data access helpers
function gameplay_data:get_floor_info(floor_number)
  return self.floors[floor_number]
end

function gameplay_data:get_npc_info_table_with_level(level)
  return filter(self.npcs, function (npc_info)
    return npc_info.level == level
  end)
end

return gameplay_data
