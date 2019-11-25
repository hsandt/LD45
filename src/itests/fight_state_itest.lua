local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local input = require("engine/input/input")
local flow = require("engine/application/flow")

local gameplay_data = require("resources/gameplay_data")

local function short_press(button_id)
  act(function ()
    input.simulated_buttons_down[0][button_id] = true
  end)
  wait(1, true)
  act(function ()
    input.simulated_buttons_down[0][button_id] = false
  end)
  wait(1, true)
end

itest_manager:register_itest('1st fight -> back to adv',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']
    local pc_fighter_prog = app.game_session.pc_fighter_progression

    -- cheat to have pc killed in 1 turn
    pc_fighter_prog.max_hp = 1
    -- fight rossmann
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_id]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- reply with first reply
  short_press(button_ids.o)

  wait(2.0)

  -- quote match resolution: pc has only 1 hp, so dies immediately and fight ends

  -- also wait for victory_anim_duration 
  wait(2.0)

  final_assert(function ()
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)

itest_manager:register_itest('#solo intermediate fight -> back to adv',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local fm = app.managers[':fight']
    local pc_fighter_prog = app.game_session.pc_fighter_progression

    -- cheat to have pc killed in 2 turns
    pc_fighter_prog.max_hp = 2

    -- let ai control pc so we pick matching replies when possible
    -- we'll still need to press confirm button to skip normal dialogues,
    --   but quote bubbles should play automatically
    pc_fighter_prog.control_type = control_types.ai

    -- give more knowledge to pc fighter just to see good replies coming
    pc_fighter_prog.known_reply_ids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    pc_fighter_prog.known_quote_match_ids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

    -- fight rossmann
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_id]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- both player and opponent should auto-attack
  -- so wait until someone dies
  wait(15)

  -- skip any remaining blocking dialogue to end the fight
  short_press(button_ids.o)
  wait(2.0)

  -- opponent depends a bit on randomness, but after all these turns
  --   we should have finished the fight and be back to the adventure for next step

  final_assert(function ()
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
