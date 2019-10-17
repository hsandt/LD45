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
  character = {
    -- pc
    [0] = sprite_data(sprite_id_location(0, 6), tile_vector(2, 5), vector(6, 39), colors.pink),
    -- npcs
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
  anim_sprites = anim_sprites,

  -- misc ui parameters

  -- characters
  pc_sprite_pos = vector(19, 78),
  npc_sprite_pos = vector(86, 78),

  -- bubble text
  bubble_screen_margin_x = 4,   -- margin-x from the screen edges
  bubble_line_max_chars = 29,   -- maximum chars per line in bubble text
  bubble_min_width = 12,
  bubble_tail_height = 4,
  rel_bubble_tail_pos_by_horizontal_dir = {
    vector(-2, -40),  -- horizontal_dirs.left  = 1
    vector( 2, -40),  -- horizontal_dirs.right = 2
  },

  -- bottom box
  bottom_box_text_topleft = vector(2, 91),
  bottom_box_max_chars = 31,

  -- health bar
  health_bar_center_x_dist_from_char = 12,
  health_bar_half_width = 2,
  health_bar_top_from_char = -36,
  health_bar_bottom_from_char = 0,

  -- fighter name label
  fighter_name_label_offset_y = 5,  -- y offset from character pos
  fighter_name_label_half_width = 35,    -- box width
}

return visual_data
