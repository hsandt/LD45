require("engine/core/class")
local ui = require("engine/ui/ui")

local visual_data = require("resources/visual_data")

speakers = enum {
  'pc',
  'npc'
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
  self.current_speaker = speakers.pc
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

  if self.current_text then
    self:draw_bubble()
    self:draw_text()
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

function dialogue_manager:draw_bubble()
  ui.draw_rounded_box(5, 20, 123, 34, colors.black, colors.white)
  visual_data.sprites.bubble_tail:render(bubble_tail_positions[self.current_speaker])
end

function dialogue_manager:draw_text()
  local top_left = visual_data.bubble_text_topleft
  api.print(wwrap(self.current_text, visual_data.bubble_line_max_chars), top_left.x, top_left.y, colors.black)
end

function dialogue_manager:say(speaker, text)
  self.current_speaker = speaker
  self.current_text = text
end

return dialogue_manager
