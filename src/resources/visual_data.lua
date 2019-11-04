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
    [0]  = sprite_data(sprite_id_location(0, 6),  tile_vector(2, 5), vector(6, 39), colors.pink),
    -- npcs
    [1]  = sprite_data(sprite_id_location(2, 6),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [2]  = sprite_data(sprite_id_location(4, 6),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [3]  = sprite_data(sprite_id_location(6, 6),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [4]  = sprite_data(sprite_id_location(8, 6),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [5]  = sprite_data(sprite_id_location(10, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [6]  = sprite_data(sprite_id_location(12, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [7]  = sprite_data(sprite_id_location(14, 6), tile_vector(2, 5), vector(9, 39), colors.pink),
    [8]  = sprite_data(sprite_id_location(4, 0),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [9]  = sprite_data(sprite_id_location(6, 0),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [10] = sprite_data(sprite_id_location(8, 0),  tile_vector(2, 5), vector(9, 39), colors.pink),
    [11] = sprite_data(sprite_id_location(10, 0), tile_vector(2, 5), vector(9, 39), colors.pink),
    [12] = sprite_data(sprite_id_location(12, 0), tile_vector(2, 5), vector(9, 39), colors.pink),
    [13] = sprite_data(sprite_id_location(14, 0), tile_vector(2, 5), vector(9, 39), colors.black),
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
  pc_sprite_pos = vector(19, 85),
  npc_sprite_pos = vector(86, 85),

  -- bubble text
  -- Margin-x from both screen edges
  -- In practice, this is the margin to the screen edge the closest to the speaker,
  --   while the margin to the farthest edge is 27
  -- But we can simulate that by setting the max number of chars below,
  --   so we can control to how far the bubble can extend in the speaker
  --   forward direction, without having to pass the faced direction to
  --   the speaker component so the dialogue manager can compute appropriate bounds.
  bubble_screen_margin_x = 4,
  bubble_line_max_chars = 24,   -- maximum chars per line in bubble text
  bubble_min_width = 12,
  bubble_tail_height = 3,
  rel_bubble_tail_pos_by_horizontal_dir = {
    vector(-2, -37),  -- horizontal_dirs.left  = 1
    vector( 2, -37),  -- horizontal_dirs.right = 2
  },
  -- in fight, first speaker bubble is shown above second one to avoid overlapping
  first_speaker_tail_offset_y = -23,

  -- bottom box
  bottom_box_topleft = vector(0, 89),
  bottom_box_max_chars = 31,

  -- health bar
  health_bar_center_x_dist_from_char = 12,
  health_bar_half_width = 2,
  health_bar_top_from_char = -36,
  health_bar_bottom_from_char = -9,

  -- fighter name label
  fighter_name_label_center_offset_x = 2,  -- x offset from character pos
  fighter_name_label_center_offset_y = -2, -- y offset from character pos
  fighter_name_label_half_width = 35,      -- box width

  -- timing (s)
  ai_say_quote_delay = 1,
  request_reply_delay = 1,
  resolve_losing_attack_delay = 1,
  resolve_exchange_delay = 1,
  check_exchange_result_delay = 1,
  request_active_fighter_action_delay = 1,
}

return visual_data
