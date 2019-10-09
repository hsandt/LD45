require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")
local wtk = require("wtk/pico8wtk")

local visual_data = require("resources/visual_data")

speakers = enum {
  'pc',
  'npc'
}

-- index must match speakers enum
local bubble_min_widths = {
  visual_data.bubble_min_width_pc,
  visual_data.bubble_min_width_npc
}

-- index must match speakers enum
local bubble_tail_positions = {
  visual_data.bubble_tail_pos_pc,
  visual_data.bubble_tail_pos_npc
}

local dialogue_manager = new_class()

dialogue_manager.type = ':dialogue'

function dialogue_manager:_init()
  -- sequence of speaker_component instances
  self.speakers = {}

  -- bottom box
  self.should_show_bottom_box = false
  self.current_bottom_text = nil
end

function dialogue_manager:start()
end

function dialogue_manager:update()
  for speaker in all(self.speakers) do
    self:update_speaker(speaker)
  end
end

function dialogue_manager:render()
  for speaker in all(self.speakers) do
    self:render_speaker(speaker)
  end

  if self.should_show_bottom_box then
    self:draw_bottom_box()
  end

  if self.current_bottom_text then
    self:draw_bottom_text()
  end
end

function dialogue_manager:add_speaker(speaker)
  add(self.speakers, speaker)
end

function dialogue_manager:update_speaker(speaker)
  if speaker.current_text and speaker.wait_for_input and input:is_just_pressed(button_ids.o) then
    speaker:stop()
  end
end

-- if speaking, render the bubble with text for that speaker
function dialogue_manager:render_speaker(speaker)
  if speaker.current_text then
    self:draw_bubble_with_text(speaker.current_text, speaker.bubble_tail_pos)
  end
end

function dialogue_manager:draw_bubble_with_text(text, bubble_tail_pos)
  local wrapped_text = wwrap(text, visual_data.bubble_line_max_chars)
  local bubble_left, bubble_top, bubble_right, bubble_bottom = dialogue_manager.compute_bubble_bounds(wrapped_text, bubble_tail_pos)
  self:draw_bubble(bubble_left, bubble_top, bubble_right, bubble_bottom, bubble_tail_pos)
  self:draw_text(wrapped_text, bubble_left, bubble_top)
end

-- static
function dialogue_manager.compute_bubble_bounds(text, bubble_tail_pos)
  -- compute bubble size to wrap around text, while respecting minimum for this character
  local max_nb_chars, nb_lines = compute_char_size(text)
  local bubble_width = max_nb_chars * character_width + 2  -- 1 px margin-x around text, and 1px border
  local bubble_height = nb_lines * character_height + 2  -- 1 px margin-y around text, and 1px border
  bubble_width = max(visual_data.bubble_min_width, bubble_width)

  local bubble_bottom = bubble_tail_pos.y - visual_data.bubble_tail_height
  local bubble_top = bubble_bottom - bubble_height
  local bubble_left
  local bubble_right

  -- try to center the bubble, but keep a margin from the both screen edges on x
  -- first check if the bubble tail is more on the left or right side
  if bubble_tail_pos.x < screen_width / 2 then
    -- tail is on left side, so if bubble is clamping, it will be on left side first
    bubble_left = flr(bubble_tail_pos.x - bubble_width / 2)
    if bubble_left < visual_data.bubble_screen_margin_x then
      bubble_left = visual_data.bubble_screen_margin_x
    end

    -- then deduce right side from left side
    -- normally it cannot be also clamped unless visual_data.bubble_line_max_chars is too high
    --   (or there is a very long word), but clamp just to be safe
    bubble_right = ceil(bubble_left + bubble_width)
    if bubble_right > screen_width - visual_data.bubble_screen_margin_x then
      bubble_right = screen_width - visual_data.bubble_screen_margin_x
    end
  else
    -- tail is on right side, so if bubble is clamping, it will be on right side first
    bubble_right = ceil(bubble_tail_pos.x + bubble_width / 2)
    if bubble_right > screen_width - visual_data.bubble_screen_margin_x then
      bubble_right = screen_width - visual_data.bubble_screen_margin_x
    end

    -- then deduce left side from left side
    bubble_left = flr(bubble_right - bubble_width)
    if bubble_left < visual_data.bubble_screen_margin_x then
      bubble_left = visual_data.bubble_screen_margin_x
    end
  end

  return bubble_left, bubble_top, bubble_right, bubble_bottom
end

function dialogue_manager:draw_bubble(bubble_left, bubble_top, bubble_right, bubble_bottom, bubble_tail_pos)
  ui.draw_rounded_box(bubble_left, bubble_top, bubble_right, bubble_bottom, colors.black, colors.white)
  visual_data.sprites.bubble_tail:render(bubble_tail_pos)
end

function dialogue_manager:draw_text(wrapped_text, bubble_left, bubble_top)
  api.print(wrapped_text, bubble_left + 2, bubble_top + 2, colors.black)
end

function dialogue_manager:draw_bottom_box()
  ui.draw_rounded_box(0, 89, 127, 127, colors.dark_blue, colors.indigo)
end

-- draw text in bottom box for narration/notification/instruction
function dialogue_manager:draw_bottom_text()
  local top_left = visual_data.bottom_box_text_topleft
  api.print(wwrap(self.current_bottom_text, visual_data.bottom_box_max_chars), top_left.x, top_left.y, colors.black)
end

return dialogue_manager
