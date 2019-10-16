-- todo: use busted --helper=.../bustedhelper instead of all the bustedhelper requires!
require("engine/test/bustedhelper")
require("engine/test/headless_itest")
require("engine/test/integrationtest")
local logging = require("engine/debug/logging")

local wit_fighter_app = require("application/wit_fighter_app")
local dialogue_manager = require("dialogue/dialogue_manager")
local fight_manager = require("fight/fight_manager")

local app = wit_fighter_app()
app.initial_gamestate = ':main_menu'

logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)
logging.file_log_stream.file_prefix = "wit_fighter_headless_itests"


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
