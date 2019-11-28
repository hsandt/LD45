local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local flow = require("engine/application/flow")

local gameplay_data = require("resources/gameplay_data")

local function register_fight_balance_itest(opponent_id, initial_attack_ids, initial_reply_ids)
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
    -- assuming each attack deals at least 1 damage (cancel will be possible later, though)
    local total_hp = gameplay_data.pc_fighter_info.initial_max_hp + opponent_info.initial_max_hp
    local estimated_fight_time = 5.0 * total_hp
    wait(estimated_fight_time)

    final_assert(function ()
      return true, "impossible"
    end)

  end)
end

-- junior accountant
register_fight_balance_itest(1, {}, {})
register_fight_balance_itest(1, {1, 3, 5, 6}, {})  -- after rossmann, as in normal play

-- junior designer
register_fight_balance_itest(2, {}, {})
register_fight_balance_itest(2, {1, 3, 5, 6}, {})  -- after rossmann, as in normal play
