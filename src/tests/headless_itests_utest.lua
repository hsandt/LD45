local itest_mode = os.getenv('ITEST_MODE')
if itest_mode == 'ignore' then
  -- skip headless itests; useful when you just want to test pure utests
  return
end

require("test/bustedhelper_game")

require("engine/test/headless_itest")
local itest_manager = require("engine/test/itest_manager")

local logging = require("engine/debug/logging")

local wit_fighter_app = require("application/wit_fighter_app")

local app = wit_fighter_app()
app.initial_gamestate = ':main_menu'

logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)
-- with busted, logs are always in log/
logging.file_log_stream.file_prefix = "wit_fighter_headless_itests"

-- clear log file on new itest session
logging.file_log_stream:clear()

logging.logger.active_categories = {
  -- engine
  ['default'] = true,
  -- ['codetuner'] = true,
  -- ['flow'] = true,
  ['itest'] = true,
  -- ['log'] = true,
  -- ['ui'] = true,
  -- ['frame'] = true,

  -- game
  ['adventure'] = true,
  ['fight'] = true,
  ['progression'] = true,
  ['speaker'] = true,
}

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
itest_manager.itest_run.app = app

-- require *_itest.lua files to automatically register them in the integration test manager
require_all_scripts_in('src', 'itests')

local should_render = check_env_should_render()
if should_render then
  print("[headless itest] enabling rendering")
end

-- randomize seed (busted needs that to give different results each time,
--   while PICO-8 will automatically randomize the seed on start)
-- ! since itests won't give the same results every time, if you want a specific result,
--   you need to force setup some variables (like the next opponent) in your specific itest
local random_seed = os.time()
-- local random_seed = 9  -- vs junior marketing, junior programmer learning match 6 -> 5 before reply 5
print("[headless itest] setting random seed to: "..random_seed)
srand(random_seed)

create_describe_headless_itests_callback(app, should_render, describe, setup, teardown, before_each, after_each, it, assert)
