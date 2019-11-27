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
  -- first is dummy attack, only used by ai when no quote left
  -- human doesn't have it and prefer skipping one's turn, as it's too punishing to have to say
  --   something dmmy and always lose
  [-1] = quote_info(-1, quote_types.attack, 0, to_big("Uh... I don't know what to say now.")),
  -- no [0] "cancel" entry for attacks
  quote_info( 1, quote_types.attack, 1, to_big("Already exhausted? You should really avoid staircases.")),
  quote_info( 2, quote_types.attack, 1, to_big("I hope your personality is not as flat as your fashion sense.")),
  quote_info( 3, quote_types.attack, 1, to_big("It took me a single day to find my job.")),
  quote_info( 4, quote_types.attack, 1, to_big("I can easily type 70 words per minute.")),
  quote_info( 5, quote_types.attack, 1, to_big("You couldn't write a sum formula in Excel.")),
  quote_info( 6, quote_types.attack, 1, to_big("Yesterday I completed all my tasks for the day under 3 hours.")),
  quote_info( 7, quote_types.attack, 2, to_big("Unlike you, all my neurons still work after 6pm.")),
  quote_info( 8, quote_types.attack, 2, to_big("I'm so good at networking I doubled the number of my contacts in a single event.")),
  quote_info( 9, quote_types.attack, 2, to_big("It was raining, you saw some light... This is how you landed here, right?")),
  quote_info(10, quote_types.attack, 2, to_big("It took me only thirty minutes to build a website for my portfolio.")),
  quote_info(11, quote_types.attack, 2, to_big("You couldn't install an app if I gave you a setup.exe.")),
  quote_info(12, quote_types.attack, 2, to_big("Unlike you, I only buy reliable devices that last at least 20 years.")),
  quote_info(13, quote_types.attack, 2, to_big("Yesterday, I stayed focused six hours straight on my computer.")),
  quote_info(14, quote_types.attack, 3, to_big("I can find any book in my shelf without lifting a finger.")),
  quote_info(15, quote_types.attack, 3, to_big("I have so much charisma I'm getting paid just for being here.")),
  quote_info(16, quote_types.attack, 3, to_big("People like you can also get here now? They really lowered the bar.")),
  quote_info(17, quote_types.attack, 3, to_big("I'm sure your website is so unsafe it gets hacked every month!!")),
  quote_info(18, quote_types.attack, 3, to_big("Don't know what to say to the boss? Just watch me and take some notes.")),
  quote_info(19, quote_types.attack, 3, to_big("A rookie like you has no chance; leave it to a pro with hands-on experience.")),
  quote_info(20, quote_types.attack, 3, to_big("I was so good at my previous job that they didn't want to let me go.")),
}

-- see doc/quote_graph.dot R nodes
local replies = {
  -- first is dummy reply, to fill menu when there are no known replies
  --   or no replies left to say
  [-1] = quote_info(-1, quote_types.reply, 0, to_big("Er...")),
  -- this is the cancel reply, that neutralizes any attack (should be available only once)
  [0] = quote_info(0, quote_types.reply, 0, to_big("Sorry, I didn't catch this one.")),
  quote_info( 1, quote_types.reply,  1, to_big("At least, mine is working.")),
  quote_info( 2, quote_types.reply,  1, to_big("By that you mean you made some big blunder, uh?")),
  quote_info( 3, quote_types.reply,  1, to_big("I knew we could count on you to make photocopies.")),
  quote_info( 4, quote_types.reply,  1, to_big("I see you spent time with the coffee machine.")),
  quote_info( 5, quote_types.reply,  1, to_big("Oh, I'm pretty sure you made some contributions toward this.")),
  quote_info( 6, quote_types.reply,  1, to_big("Well, it's about time you went to the gym for some exercise.")),
  quote_info( 7, quote_types.reply,  2, to_big("At least I didn't take the elevator, then pretend I climbed up to here.")),
  quote_info( 8, quote_types.reply,  2, to_big("I see you enjoyed your time on Discord.")),
  quote_info( 9, quote_types.reply,  2, to_big("So, do you use a plugin for that, too?")),
  quote_info(10, quote_types.reply,  2, to_big("Well, we don't all browse at 56kbps.")),
  quote_info(11, quote_types.reply,  2, to_big("Sounds easy when you've only got two of them.")),
  quote_info(12, quote_types.reply,  2, to_big("I'd rather no take anything from *you*.")),
  quote_info(13, quote_types.reply,  2, to_big("Ah, have I missed a carnival? Too bad I didn't come disguised.")),
  quote_info(14, quote_types.reply,  3, to_big("Too bad they don't mean anything to you.")),
  quote_info(15, quote_types.reply,  3, to_big("Too bad yours has so little content nobody ever cared about it.")),
  quote_info(16, quote_types.reply,  3, to_big("And I see your relatives gave you a leg-up, uh?")),
  quote_info(17, quote_types.reply,  3, to_big("Great idea. If I speak just after you I will sound competent.")),
  quote_info(18, quote_types.reply,  3, to_big("I think that's called gardening leave.")),
  quote_info(19, quote_types.reply,  3, to_big("Probably. I'm working on Linux.")),
}

-- see doc/quote_graph.dot edges
-- (default penwidth for power 1, penwidth=22 for power 2, penwidth=34 for power 3)
local quote_matches = {
  -- id, attack_id, reply_id, power
  quote_match_info( 1,  1,  6, 1),
  quote_match_info( 2,  1,  7, 2),
  quote_match_info( 3,  2, 13, 2),
  quote_match_info( 4,  2, 15, 3),
  quote_match_info( 5,  3, 10, 1),
  quote_match_info( 6,  3, 16, 3),
  quote_match_info( 7,  4,  6, 1),
  quote_match_info( 8,  4, 14, 2),
  quote_match_info( 9,  5,  9, 2),
  quote_match_info(10,  5, 19, 3),
  quote_match_info(11,  6,  3, 3),
  quote_match_info(12,  6,  5, 1),
  quote_match_info(13,  6, 11, 2),
  quote_match_info(14,  7,  4, 3),
  quote_match_info(15,  7, 11, 2),
  quote_match_info(16,  8,  8, 2),
  quote_match_info(17,  8, 11, 2),
  quote_match_info(18,  8, 13, 1),
  quote_match_info(19,  8, 14, 2),
  quote_match_info(20,  9,  7, 2),
  quote_match_info(21,  9, 16, 1),
  quote_match_info(22, 10,  9, 2),
  quote_match_info(23, 10, 15, 1),
  quote_match_info(24, 11, 12, 1),
  quote_match_info(25, 11, 19, 2),
  quote_match_info(26, 12,  4, 1),
  quote_match_info(27, 12, 10, 2),
  quote_match_info(28, 13,  1, 1),
  quote_match_info(29, 13,  6, 2),
  quote_match_info(30, 13,  8, 1),
  quote_match_info(31, 13, 10, 3),
  quote_match_info(32, 14,  6, 1),
  quote_match_info(33, 14, 11, 3),
  quote_match_info(34, 15,  4, 1),
  quote_match_info(35, 16,  5, 3),  -- be careful, that's an unsorted 16
  quote_match_info(36, 15,  6, 1),
  quote_match_info(37, 15, 18, 3),
  quote_match_info(38, 16,  6, 2),
  quote_match_info(39, 16, 16, 1),
  quote_match_info(40, 17,  1, 2),
  quote_match_info(41, 17, 15, 3),
  quote_match_info(42, 18, 12, 1),
  quote_match_info(43, 18, 17, 3),
  quote_match_info(44, 19,  2, 2),
  quote_match_info(45, 19,  3, 3),
  quote_match_info(46, 19, 17, 1),
  quote_match_info(47, 20,  2, 3),
  quote_match_info(48, 20, 18, 2),
  -- Good matches added after playtest
  quote_match_info(49,  3,  3, 3),
  quote_match_info(50,  3,  5, 2),
  quote_match_info(51,  4,  8, 2),
  quote_match_info(52,  6,  8, 3),
  quote_match_info(53,  6, 10, 1),
  quote_match_info(54,  6, 14, 1),
  quote_match_info(55, 10,  5, 1),
  quote_match_info(56, 19,  4, 2),
  -- Fun match added after playtest
  quote_match_info(57, 18,  1, 2),
}

local floors = {
  floor_info( 1,  1,  1),
  floor_info( 2,  1,  1),
  floor_info( 3,  2,  2),
  floor_info( 4,  2,  2),
  floor_info( 5,  3,  3),  -- rossmann
  floor_info( 6,  0,  0),  -- ceo with fictive level 0 (maybe prefer flag can_learn: false)
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
local pc_fighter_info = fighter_info(0, 0, 10, 4, {}, {}, {})

-- fighters are mostly mapped to characters 1:1, but storing characters separately is useful
--   in case we have a non-fighting npc
local npc_fighter_info_s = {
  -- id, character_info_id, initial_level, initial_max_hp, initial_attack_ids, initial_reply_ids
--fighter_info( 1,  1, 1, 4, {1, 2, 5},                 {6, 13, 14},                   ), -- old junior designer (good at attacks and communication topics)
--fighter_info( 2,  2, 1, 3, {4, 6},                    {1, 3, 9, 10},                 ), -- junior programmer (good at replies and tech topics)
--fighter_info( 3,  3, 1, 5, {3, 8},                    {2, 4, 6, 11},                 ), -- junior qa (tank character, good at planning topics)
--fighter_info( 4,  4, 1, 3, {2, 4, 5},                 {5, 7, 8},                     ), -- junior marketing (good at matching quotes)
--fighter_info( 5,  5, 2, 5, {1, 5, 7, 10},             {6, 7, 11, 13, 14},            ), -- designer
  fighter_info( 1,  1, 1, 3, {3, 4, 8},                    {2, 4, 6, 11}),                  -- junior accountant (good at planning topics)
  fighter_info( 2,  2, 1, 3, {1, 2, 5},                    {6, 13, 14}),                    -- junior designer (good at attacks and communication topics)
  fighter_info( 3,  3, 2, 4, {1, 4, 6, 7, 9, 11, 12, 17},  {1, 3, 9, 10, 12, 19}),          -- programmer
  fighter_info( 4,  4, 2, 5, {2, 3, 8, 10, 13, 14, 15},    {2, 4, 5, 6, 7, 8, 11, 14, 15}), -- manager (tank and planning topics, replaces qa at level 2)
--fighter_info( 8,  8, 3, 6, {1, 5, 7, 10, 14, 15},     {6, 7, 11, 13, 14, 15, 17}),      -- senior designer
--fighter_info( 9,  9, 3, 5, {4, 6, 9, 11, 12, 16, 17}, {1, 3, 9, 10, 12, 15, 16, 19}),   -- senior programmer
--fighter_info(10, 10, 3, 7, {3, 8, 10, 13, 19, 20},    {2, 4, 6, 8, 11, 18}),            -- senior qa
--fighter_info(11, 11, 3, 5, {2, 4, 5, 8, 15, 18},      {5, 7, 8, 17, 18}),               -- senior marketing

  -- make sure that this index and id matches with gameplay_data.rossmann_fighter_id
  -- learns rossmann_lv2_attack_ids immediately after tutorial fight
  fighter_info(5, 5, 3, 6, {1, 3, 5, 6}, {1, 2, 3, 7, 8, 9, 10, 11, 13, 15, 16, 17}),  -- rossmann

  -- make sure that this index and id matches with gameplay_data.ceo_fighter_id
  -- low level to avoid final boss learning your quotes... she would become invincible
  fighter_info(6, 6, 0, 8, {1, 2, 7, 5, 11, 12, 13, 14, 15, 17}, {1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 14, 15, 18, 19}),  -- ceo/boss

--#if sandbox
  fighter_info(7, 7, 99, 2, {8, 9, 14, 18, 19}, {13, 15, 17}),  -- debug man (longest quotes)
--#endif
}

local gameplay_data = {
  attacks = attacks,
  replies = replies,
  quote_matches = quote_matches,
  cancel_quote_match = quote_match_info(0, '*', 0, 0),  -- reply 0 cancels anything
  floors = floors,
  pc_info = pc_info,
  npc_info_s = npc_info_s,
  pc_fighter_info = pc_fighter_info,
  npc_fighter_info_s = npc_fighter_info_s,

  -- game session
  -- this is to show rossmann where he should be, but pc will drop to floor 1 after forced defeat anyway
  initial_floor = 5,

  -- rossmann lv2 attack ids unlocked after the 1st encounter
  rossmann_fighter_id = 5,
  ceo_fighter_id = 6,
  rossmann_lv2_attack_ids = {7, 10, 11, 13, 14, 15, 16, 18, 19, 20},

  -- fight
  losing_attack_penalty = 1,

  -- How many times ai fighter of level L must receive quote of level L
  --   to learn it. Decrements with each fighter level above quote level,
  --   but minimum is 1.
  base_learning_repetition_threshold = 2
}

-- data access helpers

function gameplay_data:get_quote(quote_type, id)
  if quote_type == quote_types.attack then
    return self.attacks[id]
  else  -- quote_type == quote_types.reply
    return self.replies[id]
  end
end

-- Return the quote match for two quote info
--   - nil if quotes are not matching at all
--   - cancel_quote_match if using the cancel reply
--   - otherwise the existing quote_match_info
function gameplay_data:get_quote_match(attack_info, reply_info)
  assert(attack_info.id >= 0, "a losing attack should be resolved immediately with resolve_losing_attack")

  if reply_info.id == 0 then
    -- cancel reply cancels any damage
    return gameplay_data.cancel_quote_match
  end

  for quote_match in all(quote_matches) do
    if quote_match.attack_id == attack_info.id and quote_match.reply_id == reply_info.id then
      return quote_match
    end
  end

  return nil
end

function gameplay_data:get_floor_info(floor_number)
  assert(self.floors[floor_number], "no floor info found at number: "..floor_number)
  return self.floors[floor_number]
end

function gameplay_data:get_all_npc_fighter_info_with_initial_level(level)
  return filter(self.npc_fighter_info_s, function (some_fighter_info)
    return some_fighter_info.initial_level == level
  end)
end

return gameplay_data
