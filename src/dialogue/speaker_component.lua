require("engine/core/class")

local visual_data = require("resources/visual_data")

-- speaker component, allows any object to register to the dialogue manager
--   and say text in a bubble

local speaker_component = new_class()

--[[
Parameters
  bubble_tail_pos: vector       position of bubble tail

State
  current_text: (string|nil)    current text said
  wait_for_input: bool          if true and current text is set,
                                next confirm input will stop saying
  higher_text: bool        if true, bubble should be shown higher
--]]
function speaker_component:_init(bubble_tail_pos)
  self.bubble_tail_pos = bubble_tail_pos
  self.current_text = nil
  self.wait_for_input = false
  self.higher_text = false
end

function speaker_component:get_final_bubble_tail_pos()
  local pos = self.bubble_tail_pos
  if self.higher_text then
    pos = pos + vector(0, visual_data.first_speaker_tail_offset_y)
  end
  return pos
end

-- Set current text and wait_for_input flag
-- Only dialogue manager can reset the flag, stopping text at the same time.
-- You must check the flag in a loop in a coroutine calling `say`.
-- higher_text defaults to false so adventure characters' bubbles always
--   show at the normal height.
function speaker_component:say(text, wait_for_input, higher_text)
  if wait_for_input == nil then
    wait_for_input = false
  end
  if higher_text == nil then
    higher_text = false
  end

  self.current_text = text
  self.wait_for_input = wait_for_input
  self.higher_text = higher_text
end

-- helper to combine say and wait_for_input flag checking loop
-- call inside coroutine only
function speaker_component:say_and_wait_for_input(text)
  self:say(text, true)

  while self.wait_for_input do
    yield()
  end
end

function speaker_component:stop()
  self.current_text = nil
  self.wait_for_input = false
  self.higher_text = false
end

return speaker_component
