require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
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
  self.current_text = nil
  self.current_speaker = nil
  self.should_show_bottom_box = false
  self.current_bottom_text = nil
end

function dialogue_manager:start()
end

function dialogue_manager:update()
end

function dialogue_manager:render()
  if self.should_show_bottom_box then
    self:draw_bottom_box()
  end

  if self.current_speaker and self.current_text then
    self:draw_bubble_with_text()
  end

  if self.current_bottom_text then
    self:draw_bottom_text()
  end
end

function dialogue_manager:draw_bottom_box()
  ui.draw_rounded_box(0, 89, 127, 127, colors.dark_blue, colors.indigo)
end

-- draw text in bottom box for narration/notification/instruction
function dialogue_manager:draw_bottom_text()
  local top_left = visual_data.bottom_box_text_topleft
  api.print(wwrap(self.current_bottom_text, visual_data.bottom_box_max_chars), top_left.x, top_left.y, colors.black)
end

function dialogue_manager:draw_bubble_with_text()
  local bubble_left, bubble_top, bubble_right, bubble_bottom = dialogue_manager.compute_bubble_bounds(self.current_speaker, self.current_text)
  self:draw_bubble(bubble_left, bubble_top, bubble_right, bubble_bottom)
  self:draw_text(bubble_left, bubble_top)
end

-- static
function dialogue_manager.compute_bubble_bounds(current_speaker, current_text)
  -- compute bubble size to wrap around text, while respecting minimum for this character
  local max_nb_chars, nb_lines = compute_char_size(current_text)
  local bubble_width = max_nb_chars * character_width + 2  -- 1 px margin-x around text, and 1px border
  local bubble_height = nb_lines * character_height + 2  -- 1 px margin-y around text, and 1px border
  bubble_width = max(bubble_min_widths[current_speaker], bubble_width)

  local bubble_left
  local bubble_top
  local bubble_right
  local bubble_bottom

  -- pc anchors bubble from bottom left, while npc anchors bubble from bottom right
  if current_speaker == speakers.pc then
    local anchor_bottom_left = visual_data.bubble_bottom_left_pc
    bubble_left = anchor_bottom_left.x
    bubble_top = anchor_bottom_left.y - bubble_height
    bubble_right = anchor_bottom_left.x + bubble_width
    bubble_bottom = anchor_bottom_left.y
  else  -- self.current_speaker == speakers.npc
    local anchor_bottom_right = visual_data.bubble_bottom_right_npc
    bubble_left = anchor_bottom_right.x - bubble_width
    bubble_top = anchor_bottom_right.y - bubble_height
    bubble_right = anchor_bottom_right.x
    bubble_bottom = anchor_bottom_right.y
  end

  return bubble_left, bubble_top, bubble_right, bubble_bottom
end

function dialogue_manager:draw_bubble(bubble_left, bubble_top, bubble_right, bubble_bottom)
  ui.draw_rounded_box(bubble_left, bubble_top, bubble_right, bubble_bottom, colors.black, colors.white)
  visual_data.sprites.bubble_tail:render(bubble_tail_positions[self.current_speaker])
end

function dialogue_manager:draw_text(bubble_left, bubble_top)
  api.print(self.current_text, bubble_left + 2, bubble_top + 2, colors.black)
end

function dialogue_manager:say(speaker, text)
  self.current_speaker = speaker
  self.current_text = wwrap(text, visual_data.bubble_line_max_chars)
end

return dialogue_manager
