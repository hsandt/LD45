local floor_info = require("content/floor_info")
local npc_info = require("content/npc_info")
local quote_info = require("content/quote_info")

local quotes = {
  quote( 1, quote_types.attack, "attack!"),
  quote( 2, quote_types.attack, "attack!"),
  quote( 3, quote_types.attack, "attack!"),
  quote( 4, quote_types.attack, "attack!"),
  quote( 5, quote_types.attack, "attack!"),
  quote( 6, quote_types.attack, "attack!"),
  quote( 7, quote_types.attack, "attack!"),
  quote( 8, quote_types.attack, "attack!"),
  quote( 9, quote_types.attack, "attack!"),
  quote( 10, quote_types.attack, "attack!"),
  quote( 11, quote_types.attack, "attack!"),
  quote( 12, quote_types.attack, "attack!"),
  quote( 13, quote_types.attack, "attack!"),
  quote( 14, quote_types.attack, "attack!"),
  quote( 15, quote_types.attack, "attack!"),
  quote( 16, quote_types.reply, "reply!"),
  quote( 17, quote_types.reply, "reply!"),
  quote( 18, quote_types.reply, "reply!"),
  quote( 19, quote_types.reply, "reply!"),
  quote( 20, quote_types.reply, "reply!"),
  quote( 21, quote_types.reply, "reply!"),
  quote( 22, quote_types.reply, "reply!"),
  quote( 23, quote_types.reply, "reply!"),
  quote( 24, quote_types.reply, "reply!"),
  quote( 25, quote_types.reply, "reply!"),
  quote( 26, quote_types.reply, "reply!"),
  quote( 27, quote_types.reply, "reply!"),
  quote( 28, quote_types.reply, "reply!"),
  quote( 29, quote_types.reply, "reply!"),
  quote( 30, quote_types.reply, "reply!"),
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
  npc_info(1, "intern designer", 1),
  npc_info(1, "intern programmer", 1),
  npc_info(1, "intern qa", 1),
  npc_info(1, "intern marketing", 1),
  npc_info(1, "placement designer", 2),
  npc_info(1, "placement programmer", 2),
  npc_info(1, "placement qa", 2),
  npc_info(1, "placement marketing", 2),
  npc_info(1, "junior designer", 3),
  npc_info(1, "junior programmer", 3),
  npc_info(1, "junior qa", 3),
  npc_info(1, "junior marketing", 3),
  npc_info(1, "designer", 4),
  npc_info(1, "programmer", 4),
  npc_info(1, "manager", 4),
  npc_info(1, "legal advisor", 4),
  npc_info(1, "senior designer", 5),
  npc_info(1, "senior programmer", 5),
  npc_info(1, "senior qa", 5),
  npc_info(1, "senior marketing", 5),
}

local gameplay_data = {
  floors = floors,
  npcs = npcs
}

return gameplay_data
