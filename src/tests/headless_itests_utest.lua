-- todo: use busted --helper=.../bustedhelper instead of all the bustedhelper requires!
require("engine/test/bustedhelper")
require("engine/test/headless_itest")
local wit_fight_app = require("application/wit_fight_app")
local dialogue_manager = require("dialogue/dialogue_manager")

-- require *_itest.lua files to automatically register them in the integration test manager
require_all_scripts_in('src', 'itests')

local app = wit_fight_app()
app.initial_gamestate = ':main_menu'
app:register_managers(dialogue_manager())

create_describe_headless_itests_callback(app, describe, setup, teardown, it, assert)
