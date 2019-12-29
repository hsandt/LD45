local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local flow = require("engine/application/flow")

local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")

itest_manager:register_itest('start -> real fights loop',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter title menu
  setup_callback(function (app)
    local pc_fighter_prog = app.game_session.pc_fighter_progression

    -- let ai control pc so we pick matching replies when possible
    -- we'll still need to press confirm button to skip normal dialogues,
    --   but quote bubbles should play automatically
    pc_fighter_prog.control_type = control_types.ai

    flow:change_gamestate_by_type(':main_menu')
  end)

  -- start game
  short_press(button_ids.o)

  -- skip pc monologue
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)

  -- repeat 10 fights
  for i = 1, 10 do
    -- start i-th fight (under AI control)
    wait(20.0)

    -- skip possible tutorial
    short_press(button_ids.o)
    short_press(button_ids.o)
    short_press(button_ids.o)
    short_press(button_ids.o)
    short_press(button_ids.o)
    short_press(button_ids.o)
    short_press(button_ids.o)
  end

  -- too hard to assert after such a long test, we just run it to detect errors
  final_assert(function (app)
    return true, "impossible"
  end)

end)

itest_manager:register_itest('start -> end with ai control on pc',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter title menu
  setup_callback(function (app)
    local pc_fighter_prog = app.game_session.pc_fighter_progression

    -- let ai control pc so we pick matching replies when possible
    -- we'll still need to press confirm button to skip normal dialogues,
    --   but quote bubbles should play automatically
    pc_fighter_prog.control_type = control_types.ai

    -- give more knowledge to pc fighter just to see good replies coming
    pc_fighter_prog.known_reply_ids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

    flow:change_gamestate_by_type(':main_menu')
  end)

  -- start game
  short_press(button_ids.o)

  -- skip pc monologue
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)

  -- start 1st fight (ai control so no need to press button everytime)
  wait(10)

  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)

  wait(10)

  -- too hard to assert after such a long test, we just run it to detect errors
  final_assert(function (app)
    return true, "impossible"
  end)

end)

--#if cheat
itest_manager:register_itest('insta-kill ceo',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- fight ceo
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.ceo_fighter_id]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip any remaining blocking dialogue to end the fight
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)
  wait(0.5)
  short_press(button_ids.o)

  final_assert(function (app)
    -- we must have killed the opponent and be back to adventure
    return flow.curr_state.type == ':main_menu', "current game state is not ':main_menu', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
--#endif
