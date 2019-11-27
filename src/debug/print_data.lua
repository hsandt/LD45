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

local function get_matching_replies(attack_info)
  -- code similar to auto_pick_reply
  local matching_replies = filter(gameplay_data.replies, function (reply)
    local reply_info = gameplay_data:get_quote(quote_types.reply, reply.id)
    local quote_match = gameplay_data:get_quote_match(attack_info, reply_info)
    return quote_match ~= nil  -- power = 0 (cancel reply) is a valid candidate
  end)
  return matching_replies
end

local function get_matching_attacks(reply_info)
  -- code similar to auto_pick_reply
  local matching_replies = filter(gameplay_data.attacks, function (attack)
    local attack_info = gameplay_data:get_quote(quote_types.attack, attack.id)
    local quote_match = gameplay_data:get_quote_match(attack_info, reply_info)
    return quote_match ~= nil  -- power = 0 (cancel reply) is a valid candidate
  end)
  return matching_replies
end

local function print_attack_and_counters_of(attack_id)
  local attack_info = gameplay_data:get_quote(quote_types.attack, attack_id)
  printh(stringify(attack_info))
  printh("=>")
  printh(joinstr_table('\n', get_matching_replies(attack_info)))
end

local function print_reply_and_attacks_countered_by(reply_id)
  local reply_info = gameplay_data:get_quote(quote_types.reply, reply_id)
  printh(stringify(reply_info))
  printh("<=")
  printh(joinstr_table('\n', get_matching_attacks(reply_info)))
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
