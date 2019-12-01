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

local function can_npc_counter(npc_fighter_info, attack_info)
  -- DEPRECATED attacks have no replies, so they would normally be considered
  -- uncounterable; ignore them instead
  if attack_info.text == "DEPRECATED" then
    return true
  end

  for reply_id in all(npc_fighter_info.initial_reply_ids) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
    if gameplay_data:get_quote_match(attack_info, reply_info) then
      return true
    end
  end
  return false
end

local function get_attacks_working_against(npc_fighter_info)
  return filter(gameplay_data.attacks, function (attack_info)
    return not can_npc_counter(npc_fighter_info, attack_info)
  end)
end

local function get_attacks_countered_by(npc_fighter_info)
  return filter(gameplay_data.attacks, function (attack_info)
    return can_npc_counter(npc_fighter_info, attack_info)
  end)
end

local function print_attack_and_counters_of(attack_id)
  local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
  printh(stringify(attack_info).." =>")
  local matching_quotes_for_attack = get_matching_quotes_for_attack(attack_info)

  local total_counter_vulnerability = 0

  for matching_quote_for_attack in all(matching_quotes_for_attack) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, matching_quote_for_attack.reply_id)
    total_counter_vulnerability = total_counter_vulnerability + matching_quote_for_attack.power + 1
    printh("  "..reply_info.." (power: "..matching_quote_for_attack.power..")")
  end

  printh("total counter vulnerability: "..total_counter_vulnerability)
end

local function print_reply_and_attacks_countered_by(reply_id)
  local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
  printh(stringify(reply_info).." <=")
  local matching_quotes_for_reply = get_matching_quotes_for_reply(reply_info)

  local total_power = 0

  for matching_quote_for_reply in all(matching_quotes_for_reply) do
    local attack_info = gameplay_data:get_quote(quote_types.attack, matching_quote_for_reply.attack_id)
    -- for total power estimation, always add 1 so "neutralized" power 0 is better than no match at all
    total_power = total_power + matching_quote_for_reply.power + 1
    printh("  "..attack_info.." (power: "..matching_quote_for_reply.power..")")
  end

  printh("total power: "..total_power)
end

local function print_attacks_working_against(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local attacks_working_against = get_attacks_working_against(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' weak against:")
  for attack_info in all(attacks_working_against) do
    printh("  "..attack_info)
  end
end

local function print_attacks_countered_by(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local attacks_working_against = get_attacks_countered_by(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' can counter:")
  for attack_info in all(attacks_working_against) do
    printh("  "..attack_info)
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

printh("=== NPC VULNERABILITIES ===\n")

for i = 1, #gameplay_data.npc_fighter_info_s do
  print_attacks_working_against(i)
  printh("")
end

-- printh("=== NPC COUNTERS ===\n")

-- for i = 1, #gameplay_data.npc_fighter_info_s do
--   print_attacks_countered_by(i)
--   printh("")
-- end
