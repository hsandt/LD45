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

itest_manager:register_itest('1st fight -> back to adv',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    -- just to avoid assert on despawn_npc, invent some npc you have supposedly
    --   spawned just before to show him during the adventure
    flow.gamestates[':adventure']:spawn_npc(2)

    -- fight rossmann
    app.managers[':fight'].next_opponent = app.game_session.npc_fighter_progressions[13]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- reply with first reply
  short_press(button_ids.o)

  wait(2.0)

  -- attack with first attack
  short_press(button_ids.o)

  -- opponent should auto-reply
  wait(2.0)

  -- quote match resolution

  -- continue until someone dies
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  wait(2.0)

  -- opponent depends a bit on randomness, but after all these turns
  --   we should have finished the fight and be back to the adventure for next step

  final_assert(function ()
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
