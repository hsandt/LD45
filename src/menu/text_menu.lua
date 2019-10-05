require("engine/application/constants")
require("engine/render/color")
local flow = require("engine/application/flow")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

-- text menu: class representing a menu with labels and arrow-based navigation
local text_menu = new_class()

-- parameters
-- items: {menu_item}      sequence of items to display
-- alignment: alignments   text alignment to use for item display
--
-- state
-- selection_index: int    index of the item currently selected
function text_menu:_init(items, alignment)
  -- parameters
  self.items = items
  self.alignment = alignment

  -- state
  self.selection_index = 1
end

-- handle navigation input
function text_menu:update()
  if input:is_just_pressed(button_ids.up) then
    self:select_previous()
  elseif input:is_just_pressed(button_ids.down) then
    self:select_next()
  elseif input:is_just_pressed(button_ids.o) then
    self:confirm_selection()
  end
end

function text_menu:select_previous()
  -- clamp selection
  self.selection_index = max(self.selection_index - 1, 1)
end

function text_menu:select_next()
  -- clamp selection
  self.selection_index = min(self.selection_index + 1, #self.items)
end

function text_menu:confirm_selection()
  -- currently, text menu is only used to navigate to other gamestates,
  -- but later, it may support generic on_confirm callbacks
  flow:query_gamestate_type(self.items[self.selection_index].target_state)
end

-- render menu, starting at top y, with text centered on x
function text_menu:draw(x, top)
  local y = top

  for i = 1, #self.items do
    -- for current selection, surround with "> <" like this: "> selected item <"
    local label = self.items[i].label
    if i == self.selection_index then
      if self.alignment == alignments.left then
        label = "> "..label
      elseif self.alignment == alignments.center then
        label = "> "..label.." <"
      end
    end
    print("label:"..label)
    print("x:"..tostr(x))
    print("y:"..tostr(y))
    ui.print_aligned(label, x, y, self.alignment, colors.white)
    y = y + character_height
  end
end

return text_menu
