-- todo: use busted --helper=.../bustedhelper instead of all the bustedhelper requires!
require("engine/test/bustedhelper")
require("engine/test/headless_itest")
require("engine/test/integrationtest")
local wit_fight_app = require("application/wit_fight_app")
local dialogue_manager = require("dialogue/dialogue_manager")

local app = wit_fight_app()
app.initial_gamestate = ':main_menu'
app:register_managers(dialogue_manager())

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
itest_runner.app = app

-- require *_itest.lua files to automatically register them in the integration test manager
require_all_scripts_in('src', 'itests')

-- check options
if contains(arg, "--render") then
  print("[headless itest] enabling rendering")
  should_render = true
end

create_describe_headless_itests_callback(app, should_render, describe, setup, teardown, it, assert)
