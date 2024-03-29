-- custom game application
-- used by main and itest_main

local gameapp = require("engine/application/gameapp")
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
local mouse = require("engine/ui/mouse")
--#endif

--#if sandbox
local sandbox_state = require("debug/sandbox_state")
--#endif
local dialogue_manager = require("dialogue/dialogue_manager")
local game_session = require("progression/game_session")
local main_menu = require("menu/main_menu")
local fight_state = require("fight/fight_state")
local fight_manager = require("fight/fight_manager")
local localizer = require("localization/localizer")
local visual_data = require("resources/visual_data")
local adventure_manager = require("story/adventure_manager")
local adventure_state = require("story/adventure_state")

local wit_fighter_app = derived_class(gameapp)

function wit_fighter_app:init()
  gameapp.init(self, fps30)

  -- components
  self.game_session = game_session()
end

function wit_fighter_app:instantiate_managers() -- override
  return {dialogue_manager(), adventure_manager(), fight_manager()}
end

function wit_fighter_app:instantiate_gamestates() -- override
  return {main_menu(), adventure_state(), fight_state(),
--#if sandbox
    sandbox_state()
--#endif
  }
end

function wit_fighter_app:on_pre_start() -- override
  -- deserialize all strings into localizer for future usage
  -- better do this on pre-start in case for manager:start needs strings
  localizer:load_all_strings()
end

--#if mouse
function wit_fighter_app:on_post_start() -- override
  -- enable mouse devkit
  input:toggle_mouse(true)
  mouse:set_cursor_sprite_data(visual_data.sprites.cursor)
end
--#endif

function wit_fighter_app:on_reset() -- override
  -- create new game session (let the old one be GC-ed)
  self.game_session = game_session()

--#if mouse
  mouse:set_cursor_sprite_data(nil)
--#endif
end

function wit_fighter_app:on_update() -- override
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

function wit_fighter_app:on_render() -- override
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
  mouse:render()
--#endif
end

return wit_fighter_app
