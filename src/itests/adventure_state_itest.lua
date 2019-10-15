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

itest_manager:register_itest('#solo player starts game',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter adventure state
  setup_callback(function ()
    flow:change_gamestate_by_type(':adventure')
  end)

  -- play intro coroutine starts

  wait(8.0)

  -- pc monologue starts

  -- skip 6 dialogue texts waiting for input
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)

  wait(8.0)

  -- check that we entered the credits state
  final_assert(function ()
    return flow.curr_state.type == ':adventure', "current game state is not ':wit_fight', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
