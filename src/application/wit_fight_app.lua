-- main entry file that uses the gameapp module for a quick bootstrap
-- the gameapp is also useful for integration tests

local gameapp = require("engine/application/gameapp")
require("engine/core/class")
local input = require("engine/input/input")

--#if tuner
local codetuner = require("engine/debug/codetuner")
--#endif

--#if log
local logging = require("engine/debug/logging")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

--#if mouse
local ui = require("engine/ui/ui")
--#endif

local game_session = require("application/game_session")
local main_menu = require("menu/main_menu")
local wit_fight = require("fight/wit_fight")
local visual_data = require("resources/visual_data")
local adventure = require("story/adventure")

local wit_fight_app = derived_class(gameapp)

function wit_fight_app:_init()
  gameapp._init(self)

  -- start new game session
  self.game_session = game_session()
end

function wit_fight_app:instantiate_gamestates() -- override
  return {main_menu(self), adventure(self), wit_fight(self)}
end

function wit_fight_app:on_pre_start() -- override
end

function wit_fight_app:on_post_start() -- override
--#if mouse
  -- enable mouse devkit
  input:toggle_mouse(true)
  ui:set_cursor_sprite_data(visual_data.sprites.cursor)
--#endif
end

function wit_fight_app:on_reset() -- override
  -- create new game session (let the old one be GC-ed)
  self.game_session = game_session()

--#if mouse
  ui:set_cursor_sprite_data(nil)
--#endif
end

function wit_fight_app:on_update() -- override
--#if profiler
  profiler.window:update()
--#endif

--#if visual_logger
  vlogger.window:update()
--#endif

--#if tuner
  codetuner:update_window()
--#endif
end

function wit_fight_app:on_render() -- override
--#if profiler
  profiler.window:render()
--#endif

--#if visual_logger
  vlogger.window:render()
--#endif

--#if tuner
  codetuner:render_window()
--#endif

--#if mouse
  -- always draw cursor on top
  ui:render_mouse()
--#endif
end

return wit_fight_app
