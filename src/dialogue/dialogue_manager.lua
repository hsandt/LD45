local manager = require("engine/application/manager")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")
local string_size = require("engine/core/string_size")
local graphics_helper = require("engine/ui/graphics_helper")
local text_helper = require("engine/ui/text_helper")

local text_menu = require("menu/text_menu_with_sfx")
local visual_data = require("resources/visual_data")

speakers = {
  pc = 1,
  npc = 2
}

local dialogue_manager = derived_class(manager)

dialogue_manager.type = ':dialogue'

function dialogue_manager:init()
  manager.init(self)

  -- component (wait for start to create text_menu so app has been registered)
  self.text_menu = nil

  -- sequence of speaker_component instances
  self.speakers = {}

  -- bottom box state
  self.should_show_bottom_box = false
  self.current_bottom_text = nil
  self.bottom_text_wait_for_input = false
  self.bottom_text_continue_hint_sprite = animated_sprite(visual_data.anim_sprites.button_o)
end

function dialogue_manager:start()  -- override
  self.text_menu = text_menu(self.app,
    visual_data.bottom_box_max_lines_count, alignments.left, colors.dark_blue,
    visual_data.bottom_text_previous_page_arrow_sprite_offset)
end

function dialogue_manager:update()  -- override
  self.text_menu:update()

  for speaker in all(self.speakers) do
    dialogue_manager.update_speaker(speaker)
  end

  -- continue bottom text on input
  if self.bottom_text_wait_for_input then
    if input:is_just_pressed(button_ids.o) then
      self:hide_bottom_text()
    else
      self.bottom_text_continue_hint_sprite:update()
    end
  end
end

function dialogue_manager:render()  -- override
  for speaker in all(self.speakers) do
    dialogue_manager.render_speaker(speaker)
  end

  if self.should_show_bottom_box then
    self:draw_bottom_box()
  end

  if self.text_menu.active then
    local top_left = visual_data.bottom_box_topleft + vector(2, 2)  -- padding 2px
    self.text_menu:draw(top_left.x, top_left.y)
  elseif self.current_bottom_text then
    self:draw_bottom_text()
  end
end

function dialogue_manager:add_speaker(speaker)
  add(self.speakers, speaker)
end

function dialogue_manager:remove_speaker(speaker)
  del(self.speakers, speaker)
end

-- prompt items: {menu_item}
function dialogue_manager:prompt_items(items, initial_selection)
  self.text_menu:show_items(items, initial_selection)
end

function dialogue_manager:show_bottom_text_and_wait_for_input(text)
  self.current_bottom_text = text
  self.bottom_text_wait_for_input = true
  self.bottom_text_continue_hint_sprite:play('press_loop')

  -- just wait for input and return (hide_bottom_text will take care of cleaning text)
  while self.bottom_text_wait_for_input do
    yield()
  end
end

function dialogue_manager:hide_bottom_text()
  self.current_bottom_text = nil
  if self.bottom_text_wait_for_input then
    self.bottom_text_wait_for_input = false
    self.bottom_text_continue_hint_sprite:stop()
  end
end

-- render

-- draw text in bottom box for narration/notification/instruction
function dialogue_manager:draw_bottom_text()
  local top_left = visual_data.bottom_box_topleft + vector(2, 2)  -- padding 2px
  api.print(text_helper.wwrap(self.current_bottom_text, visual_data.bottom_box_max_chars_per_line), top_left.x, top_left.y, colors.black)

  if self.bottom_text_wait_for_input then
    self:draw_bottom_text_continue_hint()
  end
end

function dialogue_manager:draw_bottom_text_continue_hint()
  self.bottom_text_continue_hint_sprite:render(visual_data.bottom_text_continue_hint_sprite_pos)
end

-- static
function dialogue_manager.update_speaker(speaker)
  if speaker.wait_for_input then
    if input:is_just_pressed(button_ids.o) then
      speaker:stop()
    else
      speaker.continue_hint_sprite:update()
    end
  end
end

-- if speaking, render the bubble with text for that speaker
-- static
function dialogue_manager.render_speaker(speaker)
  if speaker.current_text then
    dialogue_manager.draw_bubble_with_text(speaker.bubble_type, speaker.current_text, speaker:get_final_bubble_tail_pos(), speaker.wait_for_input, speaker.continue_hint_sprite)
  end
end

-- static
function dialogue_manager.draw_bubble_with_text(bubble_type, text, bubble_tail_pos, wait_for_input, continue_hint_sprite)
  local wrapped_text = text_helper.wwrap(text, visual_data.bubble_line_max_chars)
  local bubble_left, bubble_top, bubble_right, bubble_bottom = dialogue_manager.compute_bubble_bounds(bubble_type, wrapped_text, bubble_tail_pos)
  dialogue_manager.draw_bubble(bubble_type, bubble_left, bubble_top, bubble_right, bubble_bottom, bubble_tail_pos)
  dialogue_manager.draw_text(wrapped_text, bubble_left, bubble_top)
  if wait_for_input then
    dialogue_manager.draw_continue_hint(continue_hint_sprite, bubble_right, bubble_bottom, bubble_tail_pos)
  end
end

-- static
function dialogue_manager.compute_bubble_bounds(bubble_type, text, bubble_tail_pos)
  -- compute bubble size to wrap around text, while respecting minimum for this character
  local text_width, text_height = string_size.compute_size(text)
  -- add border of 1px for the bubble (actually 2px with left+right, top+bottom,
  --   but since we compute right = left + width, bottom = top + height, we exclude the initial pixel)
  local bubble_width, bubble_height = text_width + 1, text_height + 1
  bubble_width = max(visual_data.bubble_min_width, bubble_width)

  local bubble_bottom = bubble_tail_pos.y - visual_data.bubble_tail_height_by_bubble_type[bubble_type]
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

-- static
function dialogue_manager.draw_bubble(bubble_type, bubble_left, bubble_top, bubble_right, bubble_bottom, bubble_tail_pos)
  graphics_helper.draw_rounded_box(bubble_left, bubble_top, bubble_right, bubble_bottom, colors.black, colors.white)
  visual_data.sprites.bubble_tail_by_bubble_type[bubble_type]:render(bubble_tail_pos)
end

-- static
function dialogue_manager.draw_text(wrapped_text, bubble_left, bubble_top)
  api.print(wrapped_text, bubble_left + 2, bubble_top + 2, colors.black)
end

-- static
function dialogue_manager.draw_continue_hint(continue_hint_sprite, bubble_right, bubble_bottom, bubble_tail_pos)
  local pos = vector(bubble_right, bubble_bottom) + visual_data.continue_hint_offset
  local min_x = bubble_tail_pos.x + visual_data.continue_hint_min_offset_x_from_bubble_tail
  pos.x = max(min_x, pos.x)
  continue_hint_sprite:render(pos)
end

-- static
function dialogue_manager.draw_bottom_box()
  graphics_helper.draw_rounded_box(visual_data.bottom_box_topleft.x, visual_data.bottom_box_topleft.y,
    visual_data.bottom_box_bottomright.x, visual_data.bottom_box_bottomright.y, colors.dark_blue, colors.indigo)
end

return dialogue_manager
