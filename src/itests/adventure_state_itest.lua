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
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- here we create a fictive npc fighter we have just beat
    -- if you set next_opponent, you need an npc to despawn to avoid errors
    am:spawn_npc(2)

    -- we supposedly beat npc 1
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]
    fm.won_last_fight = true
    app.game_session.fight_count = 10  -- high count to avoid unwanted tutorials

    am.next_step = 'floor_loop'

    flow:change_gamestate_by_type(':adventure')
  end)

  -- skip enough dialogues to start next fight,
  --   but not too much to avoid finishing the fight already
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
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

itest_manager:register_itest('play floor loop at boss floor',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter adventure state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    app.game_session.floor_number = 11
    am.next_step = 'floor_loop'

    flow:change_gamestate_by_type(':adventure')
  end)

  -- skip enough dialogues to start next fight,
  --   but not too much to avoid finishing the fight already
  -- dialogue with ceo is much longer
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
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
