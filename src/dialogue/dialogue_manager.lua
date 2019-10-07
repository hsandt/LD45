require("engine/core/class")
local ui = require("engine/ui/ui")

local visual_data = require("resources/visual_data")

local dialogue_manager = new_class()

dialogue_manager.type = ':dialogue'

local bubble_tail_positions = {
  visual_data.bubble_tail_pos_pc,
  visual_data.bubble_tail_pos_npc
}

function dialogue_manager:_init()
  self.current_text = ''
  self.current_speaker_index = 1  -- 1 for pc, 2 for npc
end

function dialogue_manager:start()
end

function dialogue_manager:update()
end

function dialogue_manager:render()
  if #self.current_text > 0 then
    self:draw_bubble()
    self:draw_text()
  end
end

function dialogue_manager:draw_bubble()
  ui.draw_rounded_box(5, 20, 123, 34, colors.black, colors.white)
  visual_data.sprites.bubble_tail:render(bubble_tail_positions[self.current_speaker_index])
end

function dialogue_manager:draw_text()
  api.print(wwrap(self.current_text, visual_data.bubble_line_width), 7, 22, colors.black)
end

return dialogue_manager
