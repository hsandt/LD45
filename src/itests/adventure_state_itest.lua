local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local flow = require("engine/application/flow")

local gameplay_data = require("resources/gameplay_data")

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
  final_assert(function (app)
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

  -- unfortunately, some random fights have longer intros and battle duration than others,
  --   so don't check that we are exactly in the fight state as we may have already finished the fight
  -- ideally we would have a detector that succeeds the test as soon as we enter the fight state,
  --   but we cannot check that right now
  final_assert(function (app)
    return true, "impossible"
  end)

end)

itest_manager:register_itest('after winning fight on 2F for the second time, go to 3F when confirming first choice in menu',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local gs = app.game_session
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- win at 2F to reach 3F
    gs.floor_number = 2
    -- we've already been at 3F, so the game offers us to restart at 1F or continue to 3F
    gs.max_unlocked_floor = 3
    -- high count to avoid unwanted tutorials (although tuto 1 has a safety check not to decrease max hp)
    gs.fight_count = 10

    -- fight junior accountant (doesn't matter)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill to win and go to next floor
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue and aftermath until going to and unlocking next floor
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)

  -- floor selection: confirm first choice, 3F
  short_press(button_ids.o)

  -- wait for fade-out and actually changing floor (it takes 0.7s at fade speed = 10)
  wait(1)

  -- unfortunately, some random fights have longer intros and battle duration than others,
  --   so don't check that we are exactly in the fight state as we may have already finished the fight
  -- ideally we would have a detector that succeeds the test as soon as we enter the fight state,
  --   but we cannot check that right now
  final_assert(function (app)
    return app.game_session.floor_number == 3, "Current floor is "..app.game_session.floor_number..", expected 3"
  end)

end)

itest_manager:register_itest('after winning fight on 2F for the second time, go back to 1F when confirming second choice in menu',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local gs = app.game_session
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- win at 2F to reach 3F
    gs.floor_number = 2
    -- we've already been at 3F, so the game offers us to restart at 1F or continue to 3F
    gs.max_unlocked_floor = 3
    -- high count to avoid unwanted tutorials (although tuto 1 has a safety check not to decrease max hp)
    gs.fight_count = 10

    -- fight junior accountant (doesn't matter)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill to win and go to next floor
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue and aftermath until going to and unlocking next floor
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)
  short_press(button_ids.o)
  wait(2)

  -- floor selection: move down to select 1F, and confirm
  short_press(button_ids.down)
  short_press(button_ids.o)

  -- wait for fade-out and actually changing floor (it takes 0.7s at fade speed = 10)
  wait(1)

  -- unfortunately, some random fights have longer intros and battle duration than others,
  --   so don't check that we are exactly in the fight state as we may have already finished the fight
  -- ideally we would have a detector that succeeds the test as soon as we enter the fight state,
  --   but we cannot check that right now
  final_assert(function (app)
    return app.game_session.floor_number == 1 and app.game_session.max_unlocked_floor == 3,
      "Current floor is "..app.game_session.floor_number.." and max_unlocked_floor is "..app.game_session.max_unlocked_floor..
      ", expected 1 and 3"
  end)

end)

--#if cheat
itest_manager:register_itest('after first fight, pc max hp increase to 3', {':fight'}, function ()

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

  -- use insta-kill (of course we should lose,
  --   but the aftermath/forced floor will trigger anyway)
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue
  short_press(button_ids.o)
  wait(2.0)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)
  wait(1.0)
  short_press(button_ids.o)

  final_assert(function (app)
    local gs = app.game_session
    return gs.pc_fighter_progression.max_hp == 3, "pc max_hp is "..gs.pc_fighter_progression.max_hp..", expected 3"
  end)

end)
--#endif

--#if cheat
itest_manager:register_itest('after fight leading to 3F for first time, pc max hp increase to 4', {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local gs = app.game_session
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- win at 2F to reach 3F
    gs.floor_number = 2
    -- high count to avoid unwanted tutorials (although tuto 1 has a safety check not to decrease max hp)
    gs.fight_count = 10

    -- fight junior accountant (doesn't matter)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill to win and go to next floor
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue
  short_press(button_ids.o)

  final_assert(function (app)
    local gs = app.game_session
    return gs.pc_fighter_progression.max_hp == 4, "pc max_hp is "..gs.pc_fighter_progression.max_hp..", expected 4"
  end)

end)
--#endif

--#if cheat
itest_manager:register_itest('after fight leading to 3F after reaching 5F (max hp = 5), DO NOT reduce pc max hp back to 4', {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local gs = app.game_session
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- pc has already gone to 5F and got max hp = 5
    gs.pc_fighter_progression.max_hp = 5
    -- win at 2F to reach 3F
    gs.floor_number = 2
    -- high count to avoid unwanted tutorials (although tuto 1 has a safety check not to decrease max hp)
    gs.fight_count = 10

    -- fight junior accountant (doesn't matter)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill to win and go to next floor
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue
  short_press(button_ids.o)

  final_assert(function (app)
    local gs = app.game_session
    return gs.pc_fighter_progression.max_hp == 5, "pc max_hp is "..gs.pc_fighter_progression.max_hp..", expected 5"
  end)

end)
--#endif

--#if cheat
itest_manager:register_itest('after fight leading to 5F for first time, pc max hp increase to 5', {':fight'}, function ()

  -- enter fight state
  setup_callback(function (app)
    local gs = app.game_session
    local am = app.managers[':adventure']
    local fm = app.managers[':fight']

    -- win at 3F to reach 4F
    gs.floor_number = 4
    -- high count to avoid unwanted tutorials (although tuto 1 has a safety check not to decrease max hp)
    gs.fight_count = 10

    -- fight junior accountant (doesn't matter)
    fm.next_opponent = app.game_session.npc_fighter_progressions[1]

    flow:change_gamestate_by_type(':fight')
  end)

  -- fight start

  wait(2.0)

  -- opponent should auto-attack

  -- use insta-kill to win and go to next floor
  short_press(button_ids.x)

  -- wait for victory_anim_duration
  wait(2.0)

  -- skip dialogue
  short_press(button_ids.o)

  final_assert(function (app)
    local gs = app.game_session
    return gs.pc_fighter_progression.max_hp == 5, "pc max_hp is "..gs.pc_fighter_progression.max_hp..", expected 4"
  end)

end)
--#endif

itest_manager:register_itest('play floor loop at boss floor',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':adventure'}, function ()

  -- enter adventure state
  setup_callback(function (app)
    local am = app.managers[':adventure']
    app.game_session.fight_count = 10  -- high count to avoid unwanted tutorials
    app.game_session.floor_number = #gameplay_data.floors  -- last floor
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

  -- check that we entered the fight state
  final_assert(function (app)
    return flow.curr_state.type == ':fight', "current game state is not ':fight', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
