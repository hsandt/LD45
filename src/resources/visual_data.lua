require("engine/core/math")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")
require("engine/render/color")
local ui = require("engine/ui/ui")

local quote_info = require("content/quote_info")  -- quote_types
local fighter_progression = require("progression/fighter_progression")  -- character_types

local sprites = {
  -- blank: don't put anything in the bottom-right 8x8 sprite location
  blank = sprite_data(sprite_id_location(15, 15), tile_vector(1, 1), vector.zero(), colors.pink),
  -- ui
  cursor = sprite_data(sprite_id_location(1, 0)),
  bubble_tail_by_bubble_type = {
    sprite_data(sprite_id_location(2, 0), tile_vector(1, 1), vector(3, 7), colors.pink),  -- speech
    sprite_data(sprite_id_location(2, 3), tile_vector(2, 1), vector(1, 6), colors.pink)   -- thought
  },
  button_o = {
    idle    = sprite_data(sprite_id_location(0, 14), tile_vector(2, 2), vector(6, 6), colors.pink),
    pressed = sprite_data(sprite_id_location(2, 14), tile_vector(2, 2), vector(6, 6), colors.pink)
  },
  -- background
  upper_stairs_step1 = sprite_data(sprite_id_location(0, 1), tile_vector(1, 5), vector(0, 0), colors.pink),
  upper_stairs_step2 = sprite_data(sprite_id_location(1, 1), tile_vector(1, 5), vector(0, 0), colors.pink),
  lower_stairs_step  = sprite_data(sprite_id_location(2, 1), tile_vector(1, 2), vector(0, 0), colors.pink),
  ceo_room_wallpaper = sprite_data(sprite_id_location(2, 4), tile_vector(2, 2), vector(0, 0), colors.pink),
  -- characters
  character = {
    -- pc
    [0]  = sprite_data(sprite_id_location(0, 6),  tile_vector(2, 5), vector(5, 39), colors.pink),
    -- npcs
    [1]  = sprite_data(sprite_id_location(2, 6),  tile_vector(2, 5), vector(5, 39), colors.pink),
    [2]  = sprite_data(sprite_id_location(4, 6),  tile_vector(2, 5), vector(5, 39), colors.pink),
    [3]  = sprite_data(sprite_id_location(6, 6),  tile_vector(2, 5), vector(5, 39), colors.pink),
    [4]  = sprite_data(sprite_id_location(8, 6),  tile_vector(2, 5), vector(5, 39), colors.pink),
    [5]  = sprite_data(sprite_id_location(10, 6), tile_vector(2, 5), vector(5, 39), colors.pink),
    [6]  = sprite_data(sprite_id_location(12, 6), tile_vector(2, 5), vector(5, 39), colors.pink),
    -- old sprites
    -- [7]  = sprite_data(sprite_id_location(14, 6), tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [8]  = sprite_data(sprite_id_location(4, 0),  tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [9]  = sprite_data(sprite_id_location(6, 0),  tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [10] = sprite_data(sprite_id_location(8, 0),  tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [11] = sprite_data(sprite_id_location(10, 0), tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [12] = sprite_data(sprite_id_location(12, 0), tile_vector(2, 5), vector(5, 39), colors.pink),
    -- [13] = sprite_data(sprite_id_location(14, 0), tile_vector(2, 5), vector(5, 39), colors.black),
  },
  hurt_character = sprite_data(sprite_id_location(10, 11), tile_vector(3, 5), vector(6, 34), colors.pink),
  -- fx
  hit_fx = {
    sprite_data(sprite_id_location(0, 12), tile_vector(2, 2), vector(6, 6), colors.pink),
    sprite_data(sprite_id_location(2, 12), tile_vector(2, 2), vector(6, 6), colors.pink),
    sprite_data(sprite_id_location(4, 12), tile_vector(2, 2), vector(6, 6), colors.pink),
    sprite_data(sprite_id_location(6, 12), tile_vector(2, 2), vector(6, 6), colors.pink),
    sprite_data(sprite_id_location(8, 12), tile_vector(2, 2), vector(6, 6), colors.pink)
  }
}

local function generate_character_anim_sprite_data_table()
  local character_anim_sprite_data_table = {}
  -- note that the usage of # here is a bit tricky, since it counts all entries starting from 1, skipping 0
  -- but it works for our purpose
  for i = 0, #sprites.character do
    character_anim_sprite_data_table[i] = {
      ["idle"] = animated_sprite_data.create_static(sprites.character[i]),
      ["hurt"] = animated_sprite_data({sprites.hurt_character, sprites.blank, sprites.hurt_character}, 3, anim_loop_modes.freeze_last)
    }
  end
  return character_anim_sprite_data_table
end

local anim_sprites = {
  button_o = {
    ["press_loop"] = animated_sprite_data({sprites.button_o.idle, sprites.button_o.pressed}, 30, anim_loop_modes.loop)
  },
  character = generate_character_anim_sprite_data_table(),
  hit_fx = {
    ["once"] = animated_sprite_data.create(sprites.hit_fx,
      {1, 2, 3, 4, 5}, 1, anim_loop_modes.clear)
  }
}

local visual_data = {
  sprites = sprites,
  anim_sprites = anim_sprites,

  -- bg colors
  zone_paint_info_t = {
    [1] = {wall_color = colors.dark_gray, floor_color = colors.light_gray},
    [2] = {wall_color = colors.brown, floor_color = colors.orange},
    [3] = {wall_color = colors.dark_purple, floor_color = colors.pink},
  },

  -- misc ui parameters

  -- characters
  pc_sprite_pos = vector(19, 85),
  npc_sprite_pos = vector(86, 85),

  -- hurt sprite offset when facing right (flip x when facing left)
  hurt_sprite_offset_right = vector(-5, 0),

  -- hit fx: offset from character position when facing right (flip x when facing left)
  hit_fx_offset_right = vector(4, -35),

  -- hit feedback labels, indexed by:
  --   hurt character type -> hitting quote type -> representative damage
  hit_feedback_labels = {
    [character_types.pc] = {
      [quote_types.attack] = {
        -- todo: support center mode in label to avoid changing x based on text length
        [1] = ui.label("direct hit!", vector(32, 53), colors.orange),
        [2] = ui.label("direct hit!", vector(32, 53), colors.orange),
        [3] = ui.label("direct hit!", vector(32, 53), colors.red)
      },
      [quote_types.reply] = {
        [0] = ui.label("neutralized!", vector(32, 53), colors.white),
        [1] = ui.label("countered!", vector(32, 53), colors.orange),
        [2] = ui.label("countered!", vector(32, 53), colors.orange),
        [3] = ui.label("countered!", vector(32, 53), colors.red)
      }
    },
    [character_types.npc] = {
      [quote_types.attack] = {
        [1] = ui.label("direct hit!", vector(32, 53), colors.brown),
        [2] = ui.label("direct hit!", vector(32, 53), colors.brown),
        [3] = ui.label("direct hit!", vector(32, 53), colors.yellow)
      },
      [quote_types.reply] = {
        [0] = ui.label("neutralized!", vector(32, 53), colors.white),
        [1] = ui.label("ok", vector(32, 53), colors.brown),
        [2] = ui.label("smart!", vector(32, 53), colors.dark_green),
        [3] = ui.label("witty!", vector(32, 53), colors.indigo)
      }
    }
  },

  -- bubble text
  -- Margin-x from both screen edges
  -- In practice, this is the margin to the screen edge the closest to the speaker,
  --   while the margin to the farthest edge is 27
  -- But we can simulate that by setting the max number of chars below,
  --   so we can control to how far the bubble can extend in the speaker
  --   forward direction, without having to pass the faced direction to
  --   the speaker component so the dialogue manager can compute appropriate bounds.
  bubble_screen_margin_x = 4,
  bubble_line_max_chars = 27,   -- maximum chars per line in bubble text
  bubble_min_width = 12,
  bubble_tail_height_by_bubble_type = {
    3,  -- speech
    6   -- thought
  },
  bubble_tail_offset_right_by_bubble_type = {
    vector( 4, -37),  -- speech
    vector(11, -34)   -- thought
  },
  -- in fight, first speaker bubble is shown above second one to avoid overlapping
  first_speaker_tail_offset_y = -23,

  -- continue hint offset from bubble bottom-right
  continue_hint_offset = vector(-7, 6),
  -- for very short text, the hint may collide with the bubble tail, so clamp it to the right
  continue_hint_min_offset_x_from_bubble_tail = 8,

  -- bottom box
  bottom_box_topleft = vector(0, 89),
  bottom_box_max_chars_per_line = 31,
  bottom_box_max_lines_count = 6,

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
  resolve_skip_turn_delay = 1,
  skip_turn_delay = 0,
  start_victory_by_stale_delay = 1,
  resolve_exchange_delay = 1,
  check_exchange_result_delay = 1,
  request_action_after_exchange_delay = 1,
  victory_anim_duration = 2,
  defeat_anim_duration = 2,

  -- fade-in/out
  -- 1: 45 degree lines
  -- 2: lines move 2 steps to the right, 1 step up
  -- and they become more horizontal as the value increases
  -- note that the number must be an integer >= 1 due to how the filling algorithm is done
  -- (if you need lines more vertical, just make the algo symmetrical)
  fade_line_step_width = 2,
  -- how make new lines to add/remove per frame
  fade_speed = 10,
}

return visual_data
