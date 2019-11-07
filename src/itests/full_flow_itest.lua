local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local input = require("engine/input/input")
local flow = require("engine/application/flow")

local fighter_progression = require("progression/fighter_progression")

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

itest_manager:register_itest('start -> real fights loop',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter title menu
  setup_callback(function (app)
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

  -- start 1st fight
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
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)
  -- short_press(button_ids.o)
  -- wait(2.0)

  -- too hard to assert after such a long test, we just run it to detect errors
  final_assert(function ()
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
    pc_fighter_prog.known_quote_match_ids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

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
  final_assert(function ()
    return true, "impossible"
  end)

end)
