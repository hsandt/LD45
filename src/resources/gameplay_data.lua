local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local floor_info = require("content/floor_info")
local quote_info = require("content/quote_info")
local quote_match_info = require("content/quote_match_info")

-- see doc/quote_graph.dot A nodes
local attacks = {
  quote_info( 1, quote_types.attack, 1, "Already exhausted? You should really avoid staircases."),
  quote_info( 2, quote_types.attack, 1, "I hope your personality is not as flat as your fashion sense."),
  quote_info( 3, quote_types.attack, 1, "It took me a single day to find my job."),
  quote_info( 4, quote_types.attack, 1, "I can easily type 70 words per minute."),
  quote_info( 5, quote_types.attack, 1, "You couldn't write a sum formula in Excel."),
  quote_info( 6, quote_types.attack, 1, "Yesterday I completed all my tasks for the day under 3 hours."),
  quote_info( 7, quote_types.attack, 2, "Unlike you, all my neurons still work after 6pm."),
  quote_info( 8, quote_types.attack, 2, "I'm so good at networking that I doubled the number of my contacts in the course of a single event."),
  quote_info( 9, quote_types.attack, 2, "It was raining, you saw some light... This is how you landed here, right?"),
  quote_info(10, quote_types.attack, 2, "It took me only thirty minutes to build a website for my portfolio."),
  quote_info(11, quote_types.attack, 2, "You couldn't install an app if I gave you a setup.exe."),
  quote_info(12, quote_types.attack, 2, "Unlike you, I only buy reliable devices that last at least 20 years."),
  quote_info(13, quote_types.attack, 2, "Yesterday, I stayed focused six hours straight on my computer."),
  quote_info(14, quote_types.attack, 3, "My shelves are so well organized I can find any book, eyes closed/without lifting a finger."),
  quote_info(15, quote_types.attack, 3, "I have so much charisma I'm getting paid just for being here."),
  quote_info(16, quote_types.attack, 3, "People like you can also get here now? They really lowered the bar."),
  quote_info(17, quote_types.attack, 3, "I'm sure your website is so unsafe it gets hacked every month!!"),
  quote_info(18, quote_types.attack, 3, "No idea for your speech with the boss, uh? You should watch me and take some notes."),
  quote_info(19, quote_types.attack, 3, "A rookie like you has no chance; leave it to a pro with hands-on experience."),
  quote_info(20, quote_types.attack, 3, "I was so good at my previous job that they didn't want to let me go."),
}

-- see doc/quote_graph.dot R nodes
local replies = {
  -- first is dummy reply, to fill menu when there are no known replies
  --   or no replies left to say
  [-1] = quote_info(-1, quote_types.reply, 0, "..."),
  -- this is the cancel reply, that neutralizes any attack (should be available only once)
  [0] = quote_info(0, quote_types.reply, 0, "Sorry, I didn't catch this one."),
  quote_info( 1, quote_types.reply,  1, "At least, mine is working."),
  quote_info( 2, quote_types.reply,  1, "By that you mean you made some big blunder, uh?"),
  quote_info( 3, quote_types.reply,  1, "I knew we could count on you to make photocopies."),
  quote_info( 4, quote_types.reply,  1, "I see you spent time with the coffee machine."),
  quote_info( 5, quote_types.reply,  1, "Oh, I'm pretty sure you made some contributions toward this."),
  quote_info( 6, quote_types.reply,  1, "Well, it's about time you went to the gym for some exercise."),
  quote_info( 7, quote_types.reply,  2, "At least I don't pretend I came here by foot after taking the elevator through most of the floors."),
  quote_info( 8, quote_types.reply,  2, "I see you enjoyed your time on Discord."),
  quote_info( 9, quote_types.reply,  2, "So, do you use a plugin for that, too?"),
  quote_info(10, quote_types.reply,  2, "Well, we don't all browse at 56kbps."),
  quote_info(11, quote_types.reply,  2, "Sounds easy when you've only got two of them."),
  quote_info(12, quote_types.reply,  2, "I'd rather no take anything from *you*."),
  quote_info(13, quote_types.reply,  2, "Ah, have I missed a carnival? Too bad I didn't come disguised."),
  quote_info(14, quote_types.reply,  3, "Too bad they don't mean anything to you."),
  quote_info(15, quote_types.reply,  3, "Too bad yours has so little content nobody ever cared about it."),
  quote_info(16, quote_types.reply,  3, "And I see your relatives gave you a leg-up, uh?"),
  quote_info(17, quote_types.reply,  3, "Great idea. If I speak just after you I will sound competent."),
  quote_info(18, quote_types.reply,  3, "I that's called gardening leave."),
  quote_info(19, quote_types.reply,  3, "Probably. I'm working on Linux."),
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
  quote_match_info(8, 11, 2),
  quote_match_info(8, 13, 1),
  quote_match_info(8, 14, 2),
  quote_match_info(8, 8, 2),
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
  quote_match_info(15, 18, 3),
  quote_match_info(15, 4, 1),
  quote_match_info(15, 6, 1),
  quote_match_info(16, 5, 3),
  quote_match_info(16, 16, 1),
  quote_match_info(16, 6, 2),
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
  character_info(1, "intern designer", 1),
  character_info(2, "intern programmer", 2),
  character_info(3, "intern qa", 3),
  character_info(4, "intern marketing", 4),
  character_info(5, "placement designer", 5),
  character_info(6, "placement programmer", 6),
  character_info(7, "placement qa", 7),
  character_info(8, "placement marketing", 8),
  character_info(9, "junior designer", 9),
  character_info(10, "junior programmer", 10),
  character_info(11, "junior qa", 11),
  character_info(12, "junior marketing", 12),
  character_info(13, "designer", 13),
  character_info(14, "programmer", 14),
  character_info(15, "manager", 15),
  character_info(16, "legal advisor", 16),
  character_info(17, "senior designer", 17),
  character_info(18, "senior programmer", 18),
  character_info(19, "senior qa", 19),
  character_info(20, "senior marketing", 20),
}

-- "start with nothing" -> no known quotes to start with
local pc_fighter_info = fighter_info(0, 0, 1, 3, {}, {}, {})

-- fighters are mostly mapped to characters 1:1, but storing characters separately is useful
--   in case we have a non-fighting npc
local npc_fighter_info_s = {
  fighter_info( 1,  1, 1, 3, {1, 2}, {}, {}),
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
  -- quote_match is a struct, so == is equality member, so we can check
  --  if the wanted match exists directly with contain
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
