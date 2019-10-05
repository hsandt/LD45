-- main entry file that uses the gameapp module for a quick bootstrap
-- the gameapp is also useful for integration tests

local gameapp = require("engine/application/gameapp")
require("engine/core/class")
local codetuner = require("engine/debug/codetuner")
local logging = require("engine/debug/logging")
local profiler = require("engine/debug/profiler")
local vlogger = require("engine/debug/visual_logger")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

local main_menu = require("menu/main_menu")
local wit_fight = require("fight/wit_fight")
local visual_data = require("resources/visual_data")

local wit_fight_app = derived_class(gameapp)

function wit_fight_app.instantiate_gamestates() -- override
  return {main_menu(), wit_fight()}
end

function wit_fight_app.on_pre_start() -- override
end

function wit_fight_app.on_post_start() -- override
  -- enable mouse devkit
  input:toggle_mouse(true)
  ui:set_cursor_sprite_data(visual_data.sprites.cursor)
end

function wit_fight_app.on_reset() -- override
  ui:set_cursor_sprite_data(nil)
end

function wit_fight_app.on_update() -- override
  profiler.window:update()
  vlogger.window:update()
  codetuner:update_window()
end

function wit_fight_app:on_render() -- override
  profiler.window:render()
  vlogger.window:render()
  codetuner:render_window()

  -- always draw cursor on top
  ui:render_mouse()
end

return wit_fight_app
