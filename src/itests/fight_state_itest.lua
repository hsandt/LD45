local itest_manager = require("engine/test/itest_manager")
local flow = require("engine/application/flow")

local gameplay_data = require("resources/gameplay_data")

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
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_fighter_id]

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

  final_assert(function (app)
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)

--#if cheat
itest_manager:register_itest('insta-kill',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- fight rossmann
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_fighter_id]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill
  short_press(button_ids.x)

  -- spam confirm button just to make sure we cleaned everything (esp. the quote menu)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)

  -- wait for victory_anim_duration
  wait(2.0)

  final_assert(function (app)
    -- we must have killed the opponent and be back to adventure
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
--#endif

--#if cheat
itest_manager:register_itest('#solo insta-kill then change floor',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- fight some junior fighter (not rossmann to avoid long dialogue after fight)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill
  short_press(button_ids.x)

  wait(2.0)

  -- skip dialogue and confirm go to next floor
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)

  -- wait for fade out and despawn npc to happen
  wait(2.0)

  final_assert(function (app)
    -- we must have killed the opponent and be back to adventure, but this test is mostly just to test
    -- we didn't assert on despawn npc
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
--#endif

itest_manager:register_itest('intermediate fight -> back to adv',
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

    -- fight rossmann
    fm.next_opponent = app.game_session.npc_fighter_progressions[gameplay_data.rossmann_fighter_id]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- both player and opponent should auto-attack
  -- so wait until someone dies
  wait(18)

  -- skip any remaining blocking dialogue to end the fight
  short_press(button_ids.o)
  wait(2.0)

  -- opponent depends a bit on randomness, so until we decide to stub randomness, just don't check final result

  final_assert(function (app)
    return true, "impossible"
  end)

end)
