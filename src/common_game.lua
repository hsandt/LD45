-- Require all common game modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for game cartridge.
-- Usage: add require("common_game") at the top of each of your game main scripts
--  (along with "engine/common") and in bustedhelper_game

require("engine/core/fun_helper")
require("engine/core/seq_helper")
--#if minify_level3
-- already required in string (and text_helper), but re-required for early definition
-- (must be above require string)
require("engine/core/string_split")
--#endif
require("engine/core/string")
require("engine/core/vector_ext_mirror")

--#if minify_level3

-- required by animated_sprite_data, just here for early definition
require("engine/render/animated_sprite_data_enums")

--#endif

require("content/character_enums")
require("content/quote_enums")

--[[#pico8
--#if unity

require("ordered_require")

--#endif
--#pico8]]
