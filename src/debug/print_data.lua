-- this file only prints advanced DB info to the console
--   by querying gameplay_data
-- it is not really testing anything, so instead of making it a utest
--   that includes bustedhelper, I only included PICO-8 bridge (to make it work
--   in native Lua)
-- it can be run under PICO-8 to test actual data, but most of the time
--   you'll just want to run it directly as a Lua file and read the output
require("engine/test/pico8api")

local quote_info = require("content/quote_info")  -- quote_types
local gameplay_data = require("resources/gameplay_data")

-- return sequence of all quote matches referring to attack
local function get_matching_quotes_for_attack(attack_info)
  local matching_quotes_for_reply = {}
  for quote_match in all(gameplay_data.quote_matches) do
     if quote_match.attack_id == attack_info.id then
       add(matching_quotes_for_reply, quote_match)
    end
  end
  return matching_quotes_for_reply
end

local function get_matching_quotes_for_reply(reply_info)
  local matching_quotes_for_attack = {}
  for quote_match in all(gameplay_data.quote_matches) do
     if quote_match.reply_id == reply_info.id then
       add(matching_quotes_for_attack, quote_match)
    end
  end
  return matching_quotes_for_attack
end

local function print_attack_and_counters_of(attack_id)
  local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
  printh(stringify(attack_info))
  printh("=>")
  local matching_quotes_for_attack = get_matching_quotes_for_attack(attack_info)
  for matching_quote_for_attack in all(matching_quotes_for_attack) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, matching_quote_for_attack.reply_id)
    printh(reply_info.." (power: "..matching_quote_for_attack.power..")")
  end
end

local function print_reply_and_attacks_countered_by(reply_id)
  local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
  printh(stringify(reply_info))
  printh("=>")
  local matching_quotes_for_reply = get_matching_quotes_for_reply(reply_info)
  for matching_quote_for_reply in all(matching_quotes_for_reply) do
    local attack_info = gameplay_data:get_quote(quote_types.attack, matching_quote_for_reply.attack_id)
    printh(attack_info.." (power: "..matching_quote_for_reply.power..")")
  end
end

printh("=== ATTACK => REPLY ===\n")

for i = 1, #gameplay_data.attacks do
  print_attack_and_counters_of(i)
  printh("")
end

printh("=== REPLY <= ATTACK ===\n")

for i = 1, #gameplay_data.replies do
  print_reply_and_attacks_countered_by(i)
  printh("")
end
