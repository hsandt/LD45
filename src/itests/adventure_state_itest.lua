local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local input = require("engine/input/input")
local flow = require("engine/application/flow")

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

itest_manager:register_itest('play intro -> 1st fight',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter adventure state
  setup_callback(function (app)
    app.managers[':adventure'].next_step = 'intro'
    flow:change_gamestate_by_type(':adventure')
  end)

  -- play intro coroutine starts

  wait(8.0)

  -- pc monologue starts

  -- skip dialogue texts waiting for input
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)

  wait(8.0)

  -- check that we entered the fight state
  final_assert(function ()
    return flow.curr_state.type == ':fight', "current game state is not ':fight', has instead type: '"..flow.curr_state.type.."'"
  end)

end)

itest_manager:register_itest('play floor loop after won -> random fight',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter adventure state
  setup_callback(function (app)
    app.managers[':fight'].won_last_fight = true
    app.managers[':adventure'].next_step = 'floor_loop'

    -- just to avoid assert on despawn_npc, invent some npc you have supposedly
    --   fight just before
    flow.gamestates[':adventure']:spawn_npc(2)

    flow:change_gamestate_by_type(':adventure')
  end)

  -- play intro coroutine starts

  wait(8.0)

  -- pc monologue starts

  -- skip enough dialogues to start next fight,
  --   but not too much to avoid finishing the fight already
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)

  -- check that we entered the fight state
  final_assert(function ()
    return flow.curr_state.type == ':fight', "current game state is not ':fight', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
