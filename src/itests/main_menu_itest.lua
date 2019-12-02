local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager
local flow = require("engine/application/flow")

itest_manager:register_itest('player starts game',
    -- keep active_gamestate for now, for retrocompatibility with pico-sonic...
    -- but without gamestate_proxy, not used
    {':main_menu'}, function ()

  -- enter title menu
  setup_callback(function (app)
    flow:change_gamestate_by_type(':main_menu')
  end)

  short_press(button_ids.o)

  -- check that we entered the adventure state
  final_assert(function (app)
    return flow.curr_state.type == ':adventure', "current game state is not ':adventure', has instead type: '"..flow.curr_state.type.."'"
  end)

end)
