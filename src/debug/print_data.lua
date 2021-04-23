-- this file only prints advanced DB info to the console
--   by querying gameplay_data
-- it is not really testing anything, so instead of making it a utest
--   that includes bustedhelper, I only included PICO-8 bridge (to make it work
--   in native Lua) and the usual common files as it is an entry Lua file
-- it could be run under PICO-8 to test actual data (replacing first
--   require with engine/pico8/api.lua), but most of the time
--   you'll just want to run it directly as a Lua file and read the output
require("engine/test/pico8api")
require("engine/common")
require("common_game")

require("engine/core/seq_helper")

local quote_info = require("content/quote_info")  -- quote_types
local gameplay_data = require("resources/gameplay_data")
local text_data = require("resources/text_data")

-- print helper: return quote info + resolved localized string
local function to_localized_debug_string(quote_info)
  return quote_info.." \""..text_data:get_string(quote_info.localized_string_id).."\""
end

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

local function get_npc_counter_vulnerability_count_table(npc_fighter_info)
  local counter_vulnerability_count_table = {}

  for attack_id in all(npc_fighter_info.initial_attack_ids) do
    local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
    local matching_quotes_for_attack = get_matching_quotes_for_attack(attack_info)

    for matching_quote_for_attack in all(matching_quotes_for_attack) do
      -- initialize entry if needed
      if not counter_vulnerability_count_table[matching_quote_for_attack.reply_id] then
        counter_vulnerability_count_table[matching_quote_for_attack.reply_id] = 0
      end
      counter_vulnerability_count_table[matching_quote_for_attack.reply_id] = counter_vulnerability_count_table[matching_quote_for_attack.reply_id] + 1
    end
  end

  return counter_vulnerability_count_table
end

local function get_attack_total_counter_vulnerability_from_matching_quotes(matching_quotes_for_attack)
  local total_counter_vulnerability = 0
  for matching_quote_for_attack in all(matching_quotes_for_attack) do
    total_counter_vulnerability = total_counter_vulnerability + matching_quote_for_attack.power + 1
  end
  return total_counter_vulnerability
end

local function get_attack_total_counter_vulnerability(attack_info)
  local matching_quotes_for_attack = get_matching_quotes_for_attack(attack_info)
  return get_attack_total_counter_vulnerability_from_matching_quotes(matching_quotes_for_attack)
end

local function get_npc_attacks_average_counter_vulnerability(npc_fighter_info)
  local npc_attacks_total_counter_vulnerability = 0
  for attack_id in all(npc_fighter_info.initial_attack_ids) do
    local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
    local total_counter_vulnerability = get_attack_total_counter_vulnerability(attack_info)
    npc_attacks_total_counter_vulnerability = npc_attacks_total_counter_vulnerability + total_counter_vulnerability
  end

  -- we should average vulnerability over attacks, or npc with many attacks will
  -- just be considered more vulnerable
  assert(#npc_fighter_info.initial_attack_ids > 0)
  return npc_attacks_total_counter_vulnerability / #npc_fighter_info.initial_attack_ids
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

local function get_reply_total_power_from_matching_quotes(matching_quotes_for_reply)
  local total_power = 0
  for matching_quote_for_reply in all(matching_quotes_for_reply) do
    total_power = total_power + matching_quote_for_reply.power + 1
  end
  return total_power
end

local function get_reply_total_power(reply_info)
  local matching_quotes_for_reply = get_matching_quotes_for_reply(reply_info)
  return get_reply_total_power_from_matching_quotes(matching_quotes_for_reply)
end

local function get_npc_replies_total_power(npc_fighter_info)
  local npc_replies_total_power = 0
  for reply_id in all(npc_fighter_info.initial_reply_ids) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
    local total_power = get_reply_total_power(reply_info)
    npc_replies_total_power = npc_replies_total_power + total_power
  end
  return npc_replies_total_power
end

local function can_npc_counter(npc_fighter_info, attack_info)
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

local function get_unused_attacks()
  return filter(gameplay_data.attacks, function (attack_info)
    if contains(gameplay_data.rossmann_lv2_attack_ids, attack_info.id) then
      return false
    end
    for npc_fighter_info in all(gameplay_data.npc_fighter_info_s) do
      if contains(npc_fighter_info.initial_attack_ids, attack_info.id) then
        return false
      end
    end
    -- no npc knew this attack from the start
    return true
  end)
end

local function get_unused_replies()
  return filter(gameplay_data.replies, function (reply_info)
    for npc_fighter_info in all(gameplay_data.npc_fighter_info_s) do
      if contains(npc_fighter_info.initial_reply_ids, reply_info.id) then
        return false
      end
    end
    -- no npc knew this reply from the start or after rossmann level up
    return true
  end)
end

local function get_npc_attack_total_vulnerability(npc_fighter_info)
  local attacks_total_vulnerability = 0

  local attacks_working_against = get_attacks_working_against(npc_fighter_info)
  for attack_info in all(attacks_working_against) do
    -- use level as an indication of power (corresponds to direct hit)
    attacks_total_vulnerability = attacks_total_vulnerability + attack_info.level
  end

  return attacks_total_vulnerability
end

local function print_attack_and_counters_of(attack_id)
  local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
  printh(to_localized_debug_string(attack_info).." =>")
  local matching_quotes_for_attack = get_matching_quotes_for_attack(attack_info)

  for matching_quote_for_attack in all(matching_quotes_for_attack) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, matching_quote_for_attack.reply_id)
    printh("  "..to_localized_debug_string(reply_info).." (power: "..matching_quote_for_attack.power..")")
  end

  local total_counter_vulnerability = get_attack_total_counter_vulnerability_from_matching_quotes(matching_quotes_for_attack)
  printh("total counter vulnerability: "..total_counter_vulnerability)
end

local function print_reply_and_attacks_countered_by(reply_id)
  local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
  printh(to_localized_debug_string(reply_info).." <=")
  local matching_quotes_for_reply = get_matching_quotes_for_reply(reply_info)

  for matching_quote_for_reply in all(matching_quotes_for_reply) do
    local attack_info = gameplay_data:get_quote(quote_types.attack, matching_quote_for_reply.attack_id)
    -- for total power estimation, always add 1 so "neutralized" power 0 is better than no match at all
    printh("  "..to_localized_debug_string(attack_info).." (power: "..matching_quote_for_reply.power..")")
  end

  local total_power = get_reply_total_power_from_matching_quotes(matching_quotes_for_reply)
  printh("total power: "..total_power)
end

local function print_attacks_working_against(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local attacks_working_against = get_attacks_working_against(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' weak against:")
  for attack_info in all(attacks_working_against) do
    -- DEPRECATED attacks (localized string id 0) have no replies,
    -- so they would normally be considered uncounterable; ignore them instead
    if attack_info.localized_string_id ~= 0 then
      printh("  "..to_localized_debug_string(attack_info))
    end
  end
end

local function print_counters_against(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local counter_ids = get_npc_counter_vulnerability_count_table(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' has N attacks that can be countered by: (N as table value)")
  -- pairs
  for reply_id, matching_attacks_count in pairs(counter_ids) do
    local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
    printh("  "..to_localized_debug_string(reply_info).." against "..matching_attacks_count.." attacks")
  end
end

local function print_attacks_countered_by(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local attacks_working_against = get_attacks_countered_by(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' can counter:")
  for attack_info in all(attacks_working_against) do
    printh("  "..to_localized_debug_string(attack_info))
  end
end

local function print_npc_attacks_total_vulnerability(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' attacks total vulnerability:")
  printh(get_npc_attack_total_vulnerability(npc_fighter_info))
end

local function print_attacks_working_against(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  local attacks_working_against = get_attacks_working_against(npc_fighter_info)
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' weak against:")
  for attack_info in all(attacks_working_against) do
    -- DEPRECATED attacks (localized string id 0) have no replies,
    -- so they would normally be considered uncounterable; ignore them instead
    if attack_info.localized_string_id ~= 0 then
      printh("  "..to_localized_debug_string(attack_info))
    end
  end
end

local function print_npc_attacks_average_counter_vulnerability(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' attacks average counter vulnerability:")
  printh(get_npc_attacks_average_counter_vulnerability(npc_fighter_info))
end

local function print_npc_replies_total_power(npc_fighter_id)
  local npc_fighter_info = gameplay_data.npc_fighter_info_s[npc_fighter_id]
  printh("NPC "..npc_fighter_id.." '"..gameplay_data.npc_info_s[npc_fighter_info.character_info_id].name.."' replies total power:")
  printh(get_npc_replies_total_power(npc_fighter_info))
end

local function print_unused_attacks()
  local unused_attacks = get_unused_attacks()
  printh("=== UNUSED ATTACKS ===")
  for unused_attack in all(unused_attacks) do
    printh("UNUSED: "..dump(unused_attack))
    printh(to_localized_debug_string(unused_attack))
  end
  printh("")
end

local function print_unused_replies()
  local unused_replies = get_unused_replies()
  printh("=== UNUSED REPLIES ===")
  for unused_reply in all(unused_replies) do
    printh(to_localized_debug_string(unused_reply))
  end
  printh("")
end

print_unused_attacks()
print_unused_replies()

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

printh("=== NPC STATS ===\n")

for i = 1, #gameplay_data.npc_fighter_info_s do
  print_npc_attacks_total_vulnerability(i)
  print_npc_attacks_average_counter_vulnerability(i)
  print_npc_replies_total_power(i)
  printh("")
end

printh("=== NPC VULNERABILITIES ===\n")

for i = 1, #gameplay_data.npc_fighter_info_s do
  print_attacks_working_against(i)
  printh("")
end

printh("=== NPC COUNTER VULNERABILITIES ===\n")

for i = 1, #gameplay_data.npc_fighter_info_s do
  print_counters_against(i)
  printh("")
end

printh("=== NPC COUNTERS ===\n")

for i = 1, #gameplay_data.npc_fighter_info_s do
  print_attacks_countered_by(i)
  printh("")
  print_npc_replies_total_power(i)
  printh("")
end
