-- Require all common serialize modules
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for game cartridge.
-- Usage: add require("common_serialize") at the top of each of serialize_main.lua
--  (along with "engine/common")

--[[#pico8
--#if unity

require("ordered_require")

--#endif
--#pico8]]
