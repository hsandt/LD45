-- main source file for all itests, used to run itests in pico8

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_game")

local itest_manager = require("engine/test/itest_manager")

--#if log
local logging = require("engine/debug/logging")
--#endif

local wit_fighter_app = require("application/wit_fighter_app")

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
local app = wit_fighter_app()
itest_runner.app = app

-- tag to add require for itest files here
--[[add_require]]

function init()
--#if log
  -- register log streams to output logs to both the console and the file log
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.file_log_stream.file_prefix = "wit_fighter_itest"

  -- clear log file on new itest session
  logging.file_log_stream:clear()

  logging.logger.active_categories = {
    -- engine
    ['default'] = true,
    -- ['codetuner'] = nil,
    -- ['flow'] = nil,
    ['itest'] = true,
    -- ['log'] = nil,
    -- ['ui'] = nil,
    -- ['frame'] = nil,

    -- game
    ['adventure'] = true,
    ['fight'] = true,
    ['progression'] = true,
    ['speaker'] = true,
  }
--#endif

  app.initial_gamestate = ':main_menu'

  -- start first itest
  itest_manager:init_game_and_start_next_itest()
end

function _update60()
  itest_manager:handle_input()
  itest_manager:update()
end

function _draw()
  itest_manager:draw()
end
