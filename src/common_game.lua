-- Require all common game modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for game cartridge.
-- Usage: add require("common_game") at the top of each of your game main scripts
--  (along with "engine/common") and in bustedhelper_game

require("engine/core/fun_helper")
require("engine/core/seq_helper")
require("engine/core/string")
require("engine/core/vector_ext_mirror")

--[[#pico8
--#if unity

require("ordered_require")

--#endif
--#pico8]]
