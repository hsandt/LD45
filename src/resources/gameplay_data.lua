local floor_info = require("content/floor_info")
local npc_info = require("content/npc_info")
local quote_info = require("content/quote_info")

local quotes = {
  quote( 1, quote_types.attack, 1, "attack 1!"),
  quote( 2, quote_types.attack, 1, "attack 2!"),
  quote( 3, quote_types.attack, 1, "attack 3!"),
  quote( 4, quote_types.attack, 2, "attack 4!"),
  quote( 5, quote_types.attack, 2, "attack 5!"),
  quote( 6, quote_types.attack, 3, "attack 6!"),
  quote( 7, quote_types.attack, 3, "attack 7!"),
  quote( 8, quote_types.attack, 3, "attack 8!"),
  quote( 9, quote_types.attack, 4, "attack 9!"),
  quote(10, quote_types.attack, 4, "attack 10!"),
  quote(11, quote_types.attack, 5, "attack 11!"),
  quote(12, quote_types.attack, 5, "attack 12!"),
  quote(13, quote_types.attack, 5, "attack 13!"),
  quote(14, quote_types.attack, 6, "attack 14!"),
  quote(15, quote_types.attack, 6, "attack 15!"),
  quote(16, quote_types.reply,  1, "reply 1!"),
  quote(17, quote_types.reply,  1, "reply 2!"),
  quote(18, quote_types.reply,  1, "reply 3!"),
  quote(19, quote_types.reply,  2, "reply 4!"),
  quote(20, quote_types.reply,  2, "reply 5!"),
  quote(21, quote_types.reply,  3, "reply 6!"),
  quote(22, quote_types.reply,  3, "reply 7!"),
  quote(23, quote_types.reply,  3, "reply 8!"),
  quote(24, quote_types.reply,  4, "reply 9!"),
  quote(25, quote_types.reply,  4, "reply 10!"),
  quote(26, quote_types.reply,  5, "reply 11!"),
  quote(27, quote_types.reply,  5, "reply 12!"),
  quote(28, quote_types.reply,  5, "reply 13!"),
  quote(29, quote_types.reply,  6, "reply 14!"),
  quote(30, quote_types.reply,  6, "reply 15!"),
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

local npcs = {
  npc_info(1, "intern designer",      1, {1, 2}),
  npc_info(1, "intern programmer",    1, {2, 3}),
  npc_info(1, "intern qa",            1, {1, 3}),
  npc_info(1, "intern marketing",     1, {1, 2, 3}),
  npc_info(1, "placement designer",   2, {1, 4}),
  npc_info(1, "placement programmer", 2, {2, 5}),
  npc_info(1, "placement qa",         2, {3, 4}),
  npc_info(1, "placement marketing",  2, {4, 5}),
  npc_info(1, "junior designer",      3, {3, 6}),
  npc_info(1, "junior programmer",    3, {4, 7}),
  npc_info(1, "junior qa",            3, {5, 8}),
  npc_info(1, "junior marketing",     3, {4, 5, 8}),
  npc_info(1, "designer",             4, {7, 10}),
  npc_info(1, "programmer",           4, {1}),
  npc_info(1, "manager",              4, {1}),
  npc_info(1, "legal advisor",        4, {1}),
  npc_info(1, "senior designer",      5, {1}),
  npc_info(1, "senior programmer",    5, {1}),
  npc_info(1, "senior qa",            5, {1}),
  npc_info(1, "senior marketing",     5, {1}),
}

local gameplay_data = {
  floors = floors,
  npcs = npcs
}

return gameplay_data
