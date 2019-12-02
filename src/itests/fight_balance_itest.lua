local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local flow = require("engine/application/flow")

local gameplay_data = require("resources/gameplay_data")

local function register_fight_balance_itest(opponent_id, pc_max_hp, initial_attack_ids, initial_reply_ids)
  -- character_info_id should match opponent_id, but to be exact, opponent_id being
  --   used as fighter progression id, we should go through fighter info first
  local opponent_info = gameplay_data.npc_fighter_info_s[opponent_id]
  local opponent_name = gameplay_data.npc_info_s[opponent_info.character_info_id].name
  itest_manager:register_itest('vs '..opponent_name..' - knows A: '..dump_sequence(initial_attack_ids)..', R: '..dump_sequence(initial_reply_ids),
    {':fight'}, function ()

    -- enter fight state
    setup_callback(function (app)
      local fm = app.managers[':fight']
      local pc_fighter_prog = app.game_session.pc_fighter_progression

      -- let ai control pc to randomly pick matching replies when possible
      pc_fighter_prog.control_type = control_types.ai

      -- knowledge setup
      pc_fighter_prog.max_hp = pc_max_hp
      pc_fighter_prog.known_attack_ids = initial_attack_ids
      pc_fighter_prog.known_reply_ids = initial_reply_ids

      -- fight junior accountant
      fm.next_opponent = app.game_session.npc_fighter_progressions[opponent_id]

      flow:change_gamestate_by_type(':fight')
    end)

    -- fight intro
    wait(2.0)

    -- both player and opponent should auto-attack
    -- so wait until someone dies
    -- the factor is around 5 seconds per attack + reply round
    -- so we can estimate the max time of the fight from the total hp among both fighters
    -- assuming most attack deal at least 1 damage
    -- cancels and neutralizations are possible though, so add some offset
    local total_hp = gameplay_data.pc_fighter_info.initial_max_hp + opponent_info.initial_max_hp
    local estimated_fight_time = 5.0 * (total_hp + 2)
    wait(estimated_fight_time)

    final_assert(function (app)
      return true, "impossible"
    end)

  end)
end

-- first fight with rossmann
-- register_fight_balance_itest(gameplay_data.rossmann_fighter_id, 3, {}, {})

-- jr accountant
-- register_fight_balance_itest(1, 3, {1, 7}, {})  -- 1F: after rossmann, as in normal play
-- register_fight_balance_itest(1, 3, {1, 7, 6}, {6})  -- 1F: possible knowledge after vs jr designer (lose)
-- register_fight_balance_itest(1, 3, {1, 7, 3, 5, 6}, {4})  -- 2F: possible knowledge after vs jr accountant (lose) vs jr designer (win)

-- jr designer
-- register_fight_balance_itest(2, 3, {1, 7}, {})  -- 1F: after rossmann, as in normal play
-- register_fight_balance_itest(2, 3, {1, 7, 3, 5}, {4})  -- 1F: possible knowledge after vs jr accountant (lose)
-- register_fight_balance_itest(2, 3, {1, 7, 6, 3, 4, 5}, {6, 4})  -- 2F: possible knowledge after vs jr designer (lose) vs jr accountant (win)

-- -- programmer
register_fight_balance_itest(3, 4, {1, 7, 3, 5, 6, 4}, {4})  -- 3F: possible knowledge after path [A]: vs jr accountant (lose) vs jr designer (win) vs jr accountant (win)
-- -- only possible if you let player stay on 3F after losing to manager on 3F
register_fight_balance_itest(3, 4, {1, 7, 4, 5, 6, 4, 8}, {4, 3})  -- 3F: possible knowledge after path [A] + vs manager (lose)
register_fight_balance_itest(3, 4, {1, 7, 6, 3, 4, 5}, {6, 4})  -- 3F: possible knowledge after path [B]: vs jr designer (lose) vs jr accountant (win) vs jr designer (win)
-- -- only possible if you let player stay on 3F after losing to manager on 3F
register_fight_balance_itest(3, 4, {1, 7, 6, 3, 4, 5, 14}, {6, 4})  -- 3F: possible knowledge after path [B] + vs manager (lose)

-- register_fight_balance_itest(4, 4, {1, 7, 4, 5, 6, 11, 14}, {6, 3, 10, 19, 15})  -- 4F: possible knowledge after path [A] + vs programmer (lose) + vs manager (win)
-- register_fight_balance_itest(4, 4, {1, 7, 6, 3, 4, 5, 11, 14}, {6, 3, 9, 5, 8})  -- 4F: possible knowledge after path [B] + vs programmer (lose) + vs manager (win)

-- -- manager
register_fight_balance_itest(4, 4, {1, 7, 3, 5, 6, 4}, {4})  -- 3F: possible knowledge after path [A]
-- -- only possible if you let player stay on 3F after losing to programmer on 3F
register_fight_balance_itest(4, 4, {1, 7, 4, 5, 6, 4, 12}, {4, 9, 5})  -- 3F: possible knowledge after path [A] + vs programmer (lose)
register_fight_balance_itest(4, 4, {1, 7, 6, 3, 4, 5}, {6, 4})  -- 3F: possible knowledge after path [B]
-- -- only possible if you let player stay on 3F after losing to programmer on 3F
register_fight_balance_itest(4, 4, {1, 7, 6, 3, 4, 5, 18}, {6, 4, 19, 9})  -- 3F: possible knowledge after path [B] + vs programmer (lose)

-- register_fight_balance_itest(4, 4, {1, 7, 4, 5, 6, 8, 9}, {3, 6, 10})  -- 4F: possible knowledge after path [A] + vs manager (lose) + vs programmer (win)
-- -- only possible if you let player stay on 3F after losing to manager and programmer
-- register_fight_balance_itest(4, 4, {1, 7, 6, 3, 4, 5, 8, 10, 15, 17}, {6, 3, 9, 8, 10})  -- 3F: possible knowledge after path [B] + vs manager (lose) + vs programmer (lose)
