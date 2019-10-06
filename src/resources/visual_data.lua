require("engine/core/math")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")
require("engine/render/color")

local sprites = {
  -- ui
  cursor = sprite_data(sprite_id_location(1, 0)),
  bubble_tail = sprite_data(sprite_id_location(2, 0), nil, vector(3, 7), colors.pink),
  -- background
  upper_stairs_step1 = sprite_data(sprite_id_location(0, 1), tile_vector(1, 5), vector(0, 0), colors.pink),
  upper_stairs_step2 = sprite_data(sprite_id_location(1, 1), tile_vector(1, 5), vector(0, 0), colors.pink),
  lower_stairs_step  = sprite_data(sprite_id_location(2, 1), tile_vector(1, 2), vector(0, 0), colors.pink),
  -- characters
  pc                 = sprite_data(sprite_id_location(0, 6), tile_vector(2, 5), vector(6, 39), colors.pink),
  npc = {
    [1] = sprite_data(sprite_id_location(2, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [2] = sprite_data(sprite_id_location(4, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [3] = sprite_data(sprite_id_location(6, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [4] = sprite_data(sprite_id_location(8, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [5] = sprite_data(sprite_id_location(10, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [6] = sprite_data(sprite_id_location(12, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [7] = sprite_data(sprite_id_location(14, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
  }
}

local anim_sprites = {
  -- ex:
  -- gem = {
  --   idle = animated_sprite_data.create(sprites.gem,
  --     {"idle", "idle1", "idle2", "idle1"},
  --     13, true),
  --   spin = animated_sprite_data.create(sprites.gem,
  --     {"idle", "spin1", "spin2", "spin3"},
  --     13, true)
  -- }
}

local visual_data = {
  sprites = sprites,
  anim_sprites = anim_sprites
}

return visual_data
