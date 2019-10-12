-- main entry file that uses the gameapp module for a quick bootstrap
-- the gameapp is also useful for integration tests

-- we must require engine/pico8/api at the top of our main.lua, so API bridges apply to all modules
require("engine/pico8/api")

local logging = require("engine/debug/logging")

local codetuner = require("engine/debug/codetuner")

local wit_fighter_app = require("application/wit_fighter_app")
local dialogue_manager = require("dialogue/dialogue_manager")
local fight_manager = require("fight/fight_manager")

local app = wit_fighter_app()

function _init()
--#if log
  -- start logging before app in case we need to read logs about app start itself
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.file_log_stream.file_prefix = "wit_fighter"

  -- clear log file on new game session (or to preserve the previous log,
  -- you could add a newline and some "[SESSION START]" tag instead)
  logging.file_log_stream:clear()
--#endif

--#if profiler
  -- uncomment to enable profiler
  -- profiler.window:show(colors.orange)
--#endif

--#if tuner
  codetuner:show()
  codetuner.active = true
--#endif

  app.initial_gamestate = ':main_menu'
  app:register_managers(dialogue_manager(), fight_manager())
  app:start()
end

function _update()
  app:update()
end

function _draw()
  app:draw()
end
