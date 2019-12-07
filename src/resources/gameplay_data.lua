require("engine/core/helper")

local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local floor_info = require("content/floor_info")
local quote_info = require("content/quote_info")
local quote_match_info = require("content/quote_match_info")

-- string note: we use to_big until we support big/small letters completely
-- (in which case we will only show upper case characters as big chars)

-- see doc/quote_graph.dot A nodes
local attacks = {
  -- this is the "skip" attack, it automatically skips your turn
  -- - the pc fighter can always choose it
  -- - the npc fighters, and pc fighter as AI will only pick it if there is no attack is left
  [-1] = quote_info(-1, quote_types.attack, 0, to_big("Uh... I'll skip this one.")),
  -- no [0] "cancel" entry for attacks
  quote_info( 1, quote_types.attack, 1, to_big("Already exhausted? You should really avoid staircases.")),
  quote_info( 2, quote_types.attack, 3, to_big("I hope your personality is not as flat as your fashion sense.")),
  quote_info( 3, quote_types.attack, 1, to_big("It took me a single day to find my job.")),
  quote_info( 4, quote_types.attack, 1, to_big("I can easily type 70 words per minute.")),
  quote_info( 5, quote_types.attack, 1, to_big("You couldn't write a sum formula in Excel.")),
  quote_info( 6, quote_types.attack, 1, to_big("Yesterday I completed all my tasks for the day under 3 hours.")),
  quote_info( 7, quote_types.attack, 1, to_big("Unlike you, all my neurons still work at full throttle after 6pm.")),
  quote_info( 8, quote_types.attack, 2, to_big("I'm so good at networking I doubled the number of my contacts in a single event.")),
  quote_info( 9, quote_types.attack, 2, "DEPRECATED"),
  quote_info(10, quote_types.attack, 2, to_big("It took me only thirty minutes to build a website for my portfolio.")),
  quote_info(11, quote_types.attack, 2, "DEPRECATED"),
  quote_info(12, quote_types.attack, 2, to_big("My devices are much more reliable than yours, they can easily last 10 years.")),
  quote_info(13, quote_types.attack, 2, to_big("Yesterday, I stayed focused six hours straight on my computer.")),
  quote_info(14, quote_types.attack, 3, to_big("I can find any book in my shelf without lifting a finger.")),
  quote_info(15, quote_types.attack, 3, to_big("I have so much charisma I'm getting paid just for being here.")),
  quote_info(16, quote_types.attack, 3, to_big("People like you can also get here now? They really lowered the bar.")),
  quote_info(17, quote_types.attack, 3, to_big("For my website, I set up a much better security system than yours.")),
  quote_info(18, quote_types.attack, 3, to_big("You couldn't install an app if I gave you a setup.exe.")),
  quote_info(19, quote_types.attack, 3, to_big("You should leave the hard stuff to pros with hands-on experience like me.")),
  quote_info(20, quote_types.attack, 3, "DEPRECATED"),
}

-- see doc/quote_graph.dot R nodes
local replies = {
  -- first is dummy reply, to fill menu when there are no known replies
  --   or no replies left to say
  [-1] = quote_info(-1, quote_types.reply, 0, to_big("Er...")),
  -- this is the cancel reply, that neutralizes any attack (only available once, even if consume_reply = false)
  [0] = quote_info(0, quote_types.reply, 0, to_big("Sorry, I didn't catch this one.")),
  quote_info( 1, quote_types.reply,  1, to_big("At least, mine is working.")),
  quote_info( 2, quote_types.reply,  1, "DEPRECATED"),
  quote_info( 3, quote_types.reply,  2, to_big("I knew we could count on you to make photocopies.")),
  quote_info( 4, quote_types.reply,  1, to_big("I see you spent time with the coffee machine.")),
  quote_info( 5, quote_types.reply,  1, to_big("Oh, I'm pretty sure you made *some* contributions toward this.")),
  quote_info( 6, quote_types.reply,  2, to_big("You really can't stand physical exercise, can you?")),
  quote_info( 7, quote_types.reply,  2, "DEPRECATED"),
  quote_info( 8, quote_types.reply,  2, to_big("I see you enjoyed your time on Discord.")),
  quote_info( 9, quote_types.reply,  2, to_big("Oh, I don't doubt you can. Using some third-party plugin.")),
  quote_info(10, quote_types.reply,  1, to_big("Well, we don't all browse at 56kbps.")),
  quote_info(11, quote_types.reply,  2, to_big("Sounds easy when you've only got two of them.")),
  quote_info(12, quote_types.reply,  2, "DEPRECATED"),
  quote_info(13, quote_types.reply,  2, "DEPRECATED"),
  quote_info(14, quote_types.reply,  3, to_big("Too bad they don't mean anything to you.")),
  quote_info(15, quote_types.reply,  3, to_big("Too bad yours has so little content nobody ever cared about it.")),
  quote_info(16, quote_types.reply,  3, to_big("And I see your relatives gave you a leg-up, uh?")),
  quote_info(17, quote_types.reply,  3, "DEPRECATED"),
  quote_info(18, quote_types.reply,  3, "DEPRECATED"),
  quote_info(19, quote_types.reply,  3, to_big("Probably. I'm working on Linux.")),
}

-- see doc/quote_graph.dot edges
-- (default penwidth for power 1, penwidth=22 for power 2, penwidth=34 for power 3)
local quote_matches = {
  -- id, attack_id, reply_id, power
  quote_match_info( 1,  1,  6, 2),
  quote_match_info( 2,  1, 14, 0),
  quote_match_info( 3,  1, 16, 2),
  quote_match_info( 4,  2, 15, 3),
  quote_match_info( 5,  3,  3, 1),
  quote_match_info( 6,  3,  5, 0),
  quote_match_info( 7,  3, 15, 0),
  quote_match_info( 8,  3, 16, 3),
  quote_match_info( 9,  4,  4, 1),
  quote_match_info(10,  4,  6, 0),
  quote_match_info(11,  4,  8, 2),
  quote_match_info(12,  4,  9, 0),
  quote_match_info(13,  4, 14, 1),
  quote_match_info(14,  5,  9, 1),
  quote_match_info(15,  5, 19, 2),
  quote_match_info(16,  6,  3, 2),
  quote_match_info(17,  6,  5, 1),
  quote_match_info(18,  6, 11, 1),
  quote_match_info(19,  6, 14, 1),
  quote_match_info(20,  7,  4, 2),
  quote_match_info(21,  7, 11, 1),
  quote_match_info(22,  7, 14, 0),
  quote_match_info(23,  8,  8, 2),
  quote_match_info(24,  8, 11, 1),
  quote_match_info(25,  8, 14, 2),
  quote_match_info(26, 10,  1, 1),
  quote_match_info(27, 10,  5, 0),
  quote_match_info(28, 10,  9, 1),
  quote_match_info(29, 10, 15, 2),
  quote_match_info(30, 12,  4, 0),
  quote_match_info(31, 12, 10, 3),
  quote_match_info(32, 12, 11, 0),
  quote_match_info(33, 12, 14, 1),
  quote_match_info(34, 13,  1, 1),
  quote_match_info(35, 13,  6, 0),
  quote_match_info(36, 13,  8, 1),
  quote_match_info(37, 13, 10, 2),
  quote_match_info(38, 14,  6, 1),
  quote_match_info(39, 14, 11, 2),
  quote_match_info(40, 15,  4, 0),
  quote_match_info(41, 15,  6, 1),
  quote_match_info(42, 15,  8, 0),
  quote_match_info(43, 16,  5, 3),
  quote_match_info(44, 16,  6, 0),
  quote_match_info(45, 16, 16, 2),
  quote_match_info(46, 17,  1, 1),
  quote_match_info(47, 17,  9, 2),
  quote_match_info(48, 17, 15, 2),
  quote_match_info(49, 18, 19, 3),
  quote_match_info(50, 19,  3, 2),
  quote_match_info(51, 19,  4, 1),
}

local floors = {
  floor_info( 1,  1,  1),
  floor_info( 2,  1,  1),
  floor_info( 3,  2,  2),
  floor_info( 4,  2,  2),
  floor_info( 5,  3,  3),  -- rossmann
  floor_info( 6,  4,  4),  -- ceo
}

-- Floors at which a new zone starts, also where a "checkpoint" is created and the player can teleport to it
-- The entry index is also the zone number.
-- Deduce the floor range as [zone_start_floors[i], zone_start_floors[i + 1] - 1]
-- So zone 1 is [1, 2], zone 2 is [3, 4], zone 3 is [5, 5], zone 4 is [6, 6]
local zone_start_floors = {
  1, 3, 5, 6
}

-- character story and visual info
local pc_info = character_info(0, "you", 0)
local npc_info_s = {
  -- character_info(1, "old junior designer", 1),
  -- character_info(2, "junior programmer", 2),
  -- character_info(3, "junior qa", 3),
  -- character_info(4, "junior marketing", 4),
  character_info(1, "junior accountant", 1),
  character_info(2, "junior designer", 2),
  character_info(3, "programmer", 3),
  character_info(4, "manager", 4),
  -- character_info(8, "senior designer", 8),
  -- character_info(9, "senior programmer", 9),
  -- character_info(10, "senior qa", 10),
  -- character_info(11, "senior marketing", 11),
  character_info(5, "rossmann", 5),
  character_info(6, "ceo", 6),
--#if sandbox
  character_info(7, "debug man", 5),  -- reuse rossmann sprite
--#endif
}

-- "start with nothing" -> no known quotes to start with
-- pc has level 10 so he's able to learn any quote in one hearing
-- initial stamina is 2, just so pc gets defeated by rossmann in 2 hits (considering pc skips once)
--   but it may increase after 1st tutorial, depending on max_hp_after_first_tutorial
local pc_fighter_info = fighter_info(0, 0, 10, 2, {}, {}, {})

-- fighters are mostly mapped to characters 1:1, but storing characters separately is useful
--   in case we have a non-fighting npc
local npc_fighter_info_s = {
  -- id, character_info_id, initial_level, initial_max_hp, initial_attack_ids, initial_reply_ids
--fighter_info( 1,  1, 1, 4, {1, 2, 5},                 {6, 13, 14},                   ), -- old junior designer (good at attacks and communication topics)
--fighter_info( 2,  2, 1, 3, {4, 6},                    {1, 3, 9, 10},                 ), -- junior programmer (good at replies and tech topics)
--fighter_info( 3,  3, 1, 5, {3, 8},                    {2, 4, 6, 11},                 ), -- junior qa (tank character, good at planning topics)
--fighter_info( 4,  4, 1, 3, {2, 4, 5},                 {5, 7, 8},                     ), -- junior marketing (good at matching quotes)
--fighter_info( 5,  5, 2, 5, {1, 5, 7, 10},             {6, 7, 11, 13, 14},            ), -- designer
-- R3 is now level 2, so move that away
  fighter_info( 1,  1, 1, 3, {3, 4, 5},                    {1, 4, 9}),                  -- junior accountant (good at planning topics)
  fighter_info( 2,  2, 1, 3, {1, 6, 7},                    {3, 5, 6}),                    -- junior designer (good at attacks and communication topics)
  -- fighter_info( 3,  3, 2, 4, {4, 6, 7, 9, 11, 12, 13, 17},  {1, 3, 9, 10, 12, 19}),          -- programmer
  -- fighter_info( 4,  4, 2, 5, {2, 5, 10, 14, 15},    {2, 4, 5, 6, 7, 8, 11, 14, 15}), -- manager (tank and planning topics, replaces qa at level 2)
  fighter_info( 3,  3, 2, 4, {3, 4, 7, --[[new attacks]] 12, 17, 18},    {5, --[[reply to new attacks]] 1, 9, 10, 19}),          -- programmer
  fighter_info( 4,  4, 2, 5, {1, 5, 6, --[[new attacks]] 8, 10, 14, 15},    {3, --[[reply to new attacks]] 4, 6, 8}), -- manager (tank and planning topics, replaces qa at level 2)
--fighter_info( 8,  8, 3, 6, {1, 5, 7, 10, 14, 15},     {6, 7, 11, 13, 14, 15, 17}),      -- senior designer
--fighter_info( 9,  9, 3, 5, {4, 6, 9, 11, 12, 16, 17}, {1, 3, 9, 10, 12, 15, 16, 19}),   -- senior programmer
--fighter_info(10, 10, 3, 7, {3, 8, 10, 13, 19, 20},    {2, 4, 6, 8, 11, 18}),            -- senior qa
--fighter_info(11, 11, 3, 5, {2, 4, 5, 8, 15, 18},      {5, 7, 8, 17, 18}),               -- senior marketing

  -- make sure that this index and id matches with gameplay_data.rossmann_fighter_id
  -- learns rossmann_lv2_attack_ids immediately after tutorial fight
  fighter_info(5, 5, 3, 6, {1, 7}, {1, 3, 10, 15, 16, 19}),  -- rossmann (IT)

  -- make sure that this index and id matches with gameplay_data.ceo_fighter_id
  fighter_info(6, 6, 4, 8, {2, 5, 12, 14, 18, 19}, {1, 3, 5, 6, 8, 10, 11, 14, 15}),  -- ceo/boss

--#if sandbox
  fighter_info(7, 7, 99, 2, {8, 14, 19}, {15}),  -- debug man (longest quotes)
--#endif
}

local gameplay_data = {
  attacks = attacks,
  replies = replies,
  quote_matches = quote_matches,
  cancel_quote_match = quote_match_info(0, '*', 0, 0),  -- reply 0 cancels anything
  floors = floors,
  zone_start_floors = zone_start_floors,
  pc_info = pc_info,
  npc_info_s = npc_info_s,
  pc_fighter_info = pc_fighter_info,
  npc_fighter_info_s = npc_fighter_info_s,

  -- game session
  -- this is to show rossmann where he should be, but pc will drop to floor 1 after forced defeat anyway
  initial_floor = 5,

  -- special progression
  max_hp_after_first_tutorial = 3,
  max_hp_after_win_by_floor_number = {
    -- at floor [index], if you win and reach floor [index + 1], your max hp
    -- will become [value] unless they are already higher
    [2] = 4,
    [4] = 5
  },

  -- special npc data
  rossmann_fighter_id = 5,
  ceo_fighter_id = 6,
  -- rossmann lv2 attack ids unlocked after the 1st encounter
  rossmann_lv2_attack_ids = {--[[Lv2]] 8, 13, --[[Lv3]] 14, 16, 18, 19},

  -- fight

  -- How many times ai fighter of level L must receive quote of level L
  --   to learn it. Decrements with each fighter level above quote level,
  --   but minimum is 1.
  base_learning_repetition_threshold = 2,


  -- Experimental rules

  -- all fighters: cannot reuse same reply twice in a fight
  consume_reply = true,
  -- npc: when some replies are left but none matches last attack,
  --      pick a random reply instead of the losing reply
  npc_random_reply_fallback = false
}

-- data access helpers

function gameplay_data:get_quote(quote_type, id)
  if quote_type == quote_types.attack then
    return self.attacks[id]
  else  -- quote_type == quote_types.reply
    return self.replies[id]
  end
end

-- Return the quote match for two quotes, identified by info
function gameplay_data:get_quote_match(attack_info, reply_info)
  return self:get_quote_match_with_id(attack_info.id, reply_info.id)
end

-- Return the quote match for two quotes, identified by id
--   - nil if quotes are not matching at all
--   - cancel_quote_match if using the cancel reply
--   - otherwise the existing quote_match_info
function gameplay_data:get_quote_match_with_id(attack_id, reply_id)
  if attack_id <= 0 then
    return nil
  end

  if reply_id == 0 then
    -- cancel reply cancels any damage
    return gameplay_data.cancel_quote_match
  end

  for quote_match in all(quote_matches) do
    if quote_match.attack_id == attack_id and quote_match.reply_id == reply_id then
      return quote_match
    end
  end

  return nil
end

function gameplay_data:get_floor_info(floor_number)
  assert(self.floors[floor_number], "no floor info found at number: "..floor_number)
  return self.floors[floor_number]
end

function gameplay_data:get_zone(floor_number)
  -- find the lower bound for floor_number, inclusive
  for i = #self.zone_start_floors, 1, -1 do
    if self.zone_start_floors[i] <= floor_number then
      return i
    end
  end
  assert(false, "could not find zone for floor: "..floor_number..", is it positive? zone_start_floors: "..dump_sequence(zone_start_floors))
  return 0
end

function gameplay_data:get_all_npc_fighter_info_with_initial_level(level)
  return filter(self.npc_fighter_info_s, function (some_fighter_info)
    return some_fighter_info.initial_level == level
  end)
end

return gameplay_data
