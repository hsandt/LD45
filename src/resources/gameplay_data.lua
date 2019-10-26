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
  quote_info( 8, quote_types.attack, 2, to_big("I'm so good at networking that I doubled the number of my contacts in the course of a single event.")),
  quote_info( 9, quote_types.attack, 2, to_big("It was raining, you saw some light... This is how you landed here, right?")),
  quote_info(10, quote_types.attack, 2, to_big("It took me only thirty minutes to build a website for my portfolio.")),
  quote_info(11, quote_types.attack, 2, to_big("You couldn't install an app if I gave you a setup.exe.")),
  quote_info(12, quote_types.attack, 2, to_big("Unlike you, I only buy reliable devices that last at least 20 years.")),
  quote_info(13, quote_types.attack, 2, to_big("Yesterday, I stayed focused six hours straight on my computer.")),
  quote_info(14, quote_types.attack, 3, to_big("My shelves are so well organized I can find any book, eyes closed/without lifting a finger.")),
  quote_info(15, quote_types.attack, 3, to_big("I have so much charisma I'm getting paid just for being here.")),
  quote_info(16, quote_types.attack, 3, to_big("People like you can also get here now? They really lowered the bar.")),
  quote_info(17, quote_types.attack, 3, to_big("I'm sure your website is so unsafe it gets hacked every month!!")),
  quote_info(18, quote_types.attack, 3, to_big("No idea for your speech with the boss, uh? You should watch me and take some notes.")),
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
  quote_info( 7, quote_types.reply,  2, to_big("At least I don't pretend I came here by foot after taking the elevator through most of the floors.")),
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
  quote_info(18, quote_types.reply,  3, to_big("I that's called gardening leave.")),
  quote_info(19, quote_types.reply,  3, to_big("Probably. I'm working on Linux.")),
}

-- see doc/quote_graph.dot edges
-- (default penwidth for power 1, penwidth=22 for power 2, penwidth=34 for power 3)
local quote_matches = {
  quote_match_info(1, 6, 1),
  quote_match_info(1, 7, 2),
  quote_match_info(2, 13, 2),
  quote_match_info(2, 15, 3),
  quote_match_info(3, 10, 1),
  quote_match_info(3, 16, 3),
  quote_match_info(4, 6, 1),
  quote_match_info(4, 14, 2),
  quote_match_info(5, 9, 2),
  quote_match_info(5, 19, 3),
  quote_match_info(6, 3, 3),
  quote_match_info(6, 5, 1),
  quote_match_info(6, 11, 2),
  quote_match_info(7, 4, 3),
  quote_match_info(7, 11, 2),
  quote_match_info(8, 8, 2),
  quote_match_info(8, 11, 2),
  quote_match_info(8, 13, 1),
  quote_match_info(8, 14, 2),
  quote_match_info(9, 7, 2),
  quote_match_info(9, 16, 1),
  quote_match_info(10, 9, 2),
  quote_match_info(10, 15, 1),
  quote_match_info(11, 12, 1),
  quote_match_info(11, 19, 2),
  quote_match_info(12, 4, 1),
  quote_match_info(12, 10, 2),
  quote_match_info(13, 1, 1),
  quote_match_info(13, 6, 2),
  quote_match_info(13, 8, 1),
  quote_match_info(13, 10, 3),
  quote_match_info(14, 6, 1),
  quote_match_info(14, 11, 3),
  quote_match_info(15, 4, 1),
  quote_match_info(16, 5, 3),
  quote_match_info(15, 6, 1),
  quote_match_info(15, 18, 3),
  quote_match_info(16, 6, 2),
  quote_match_info(16, 16, 1),
  quote_match_info(17, 1, 2),
  quote_match_info(17, 15, 3),
  quote_match_info(18, 12, 1),
  quote_match_info(18, 17, 3),
  quote_match_info(19, 2, 2),
  quote_match_info(19, 3, 3),
  quote_match_info(19, 17, 1),
  quote_match_info(20, 2, 3),
  quote_match_info(20, 18, 2),
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
  character_info(1, "junior designer", 1),
  character_info(2, "junior programmer", 2),
  character_info(3, "junior qa", 3),
  character_info(4, "junior marketing", 4),
  character_info(5, "designer", 5),
  character_info(6, "programmer", 6),
  character_info(7, "manager", 7),
  character_info(8, "legal advisor", 8),
  character_info(9, "senior designer", 9),
  character_info(10, "senior programmer", 10),
  character_info(11, "senior qa", 11),
  character_info(12, "senior marketing", 12),
  character_info(13, "rossmann", 13),
}

-- "start with nothing" -> no known quotes to start with
-- pc has level 10 so he's able to learn any quote in one hearing
local pc_fighter_info = fighter_info(0, 0, 10, 2, {}, {}, {})

-- fighters are mostly mapped to characters 1:1, but storing characters separately is useful
--   in case we have a non-fighting npc
local npc_fighter_info_s = {
  -- id, character_info_id, initial_level, initial_max_hp, initial_attack_ids, initial_reply_ids, initial_quote_match_ids
  fighter_info( 1,  1, 1, 4, {1, 5}, {6, 13, 14}, {}),         -- junior designer (good at attacks and wits in general)
  fighter_info( 2,  2, 1, 3, {4, 6}, {3, 9, 10}, {}),          -- junior programmer (good at replies and tech topics)
  fighter_info( 3,  3, 1, 5, {3, 8}, {6, 11}, {}),             -- junior qa (tank character, good at planning topics)
  fighter_info( 4,  4, 1, 3, {4, 5, 8}, {5, 7, 8}, {}),        -- junior marketing (good at matching quotes)
  fighter_info( 5,  5, 2, 5, {7, 10}, {}, {}),                 -- designer
  fighter_info( 6,  6, 2, 4, {1}, {}, {}),                     -- programmer
  fighter_info( 7,  7, 2, 6, {1}, {}, {}),                     -- manager (tank and planning topics)
  fighter_info( 8,  8, 2, 4, {1}, {}, {}),                     -- legal advisor (good at matching quotes)
  fighter_info( 9,  9, 3, 6, {1}, {}, {}),                     -- senior designer
  fighter_info(10, 10, 3, 5, {1}, {}, {}),                     -- senior programmer
  fighter_info(11, 11, 3, 7, {1}, {}, {}),                     -- senior qa
  fighter_info(12, 12, 3, 5, {1}, {}, {}),                     -- senior marketing
  fighter_info(13, 13, 2, 3, {1, 2, 5, 6}, {}, {}), -- rossmann
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

  -- game session
  initial_floor = 3,

  -- rossmann lv2 attack ids unlocked after the 1st encounter
  rossmann_lv2_attack_ids = {7, 10, 11},

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

-- Return the quote match power for two quote info
--   - -1 if quotes are not matching at all
--   - otherwise the power of the existing quote_match_info
-- This allows us to distinguish an incorrect reply, and a cancelling
--   reply that would have a power of 0, just enough to avoid damage
--   while not dealing damage back either.
function gameplay_data:get_quote_match_power(attack_info, reply_info)
  assert(attack_info.id >= 0, "a losing attack should be resolved immediately with resolve_losing_attack")

  if reply_info.id == 0 then
    -- cancel reply cancels any damage
    return 0
  end

  for quote_match in all(quote_matches) do
    if quote_match.attack_id == attack_info.id and quote_match.reply_id == reply_info.id then
      return quote_match.power
    end
  end

  return -1
end

function gameplay_data:get_floor_info(floor_number)
  return self.floors[floor_number]
end

function gameplay_data:get_all_npc_fighter_info_with_initial_level(level)
  return filter(self.npc_fighter_info_s, function (some_fighter_info)
    return some_fighter_info.initial_level == level
  end)
end

return gameplay_data
