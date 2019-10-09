require("engine/core/class")

-- speaker component, allows any object to register to the dialogue manager
--   and say text in a bubble

local speaker_component = new_class()

-- parameters
--   bubble_tail_pos: vector        position of bubble tail
-- state
--   current_text: (string|nil)     current text said
--   wait_for_input: bool           if true and current text is set,
--                                    next confirm input will stop saying
function speaker_component:_init(bubble_tail_pos)
  self.bubble_tail_pos = bubble_tail_pos
  self.current_text = nil
  self.wait_for_input = false
end

function speaker_component:say(text, wait_for_input)
  if wait_for_input == nil then
    wait_for_input = false
  end

  self.current_text = text
  self.wait_for_input = wait_for_input
end

function speaker_component:stop()
  self.current_text = nil
  self.wait_for_input = false
end

return speaker_component
