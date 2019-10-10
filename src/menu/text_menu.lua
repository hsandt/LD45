require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/render/color")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

--[[
Class representing a menu with labels and arrow-based navigation

Instance parameters
  alignment         alignments    text alignment to use for item display
  text_color        colors        item text color

Instance dynamic parameters
  items             {menu_item}   sequence of items to display

Instance state
  active           bool           if true, the text menu is shown and receives input
  selection_index  int            index of the item currently selected
--]]

local text_menu = new_class()
function text_menu:_init(alignment, text_color)
  -- parameters
  self.alignment = alignment
  self.text_color = text_color

  -- dynamic parameters (mostly set once, but may change in some usage cases)
  self.items = {}

  -- state
  self.active = false
  self.selection_index = 0
end

-- Activate the menu, fill items with given sequence and initialise selection
--
-- We copy the sequence content to avoid referencing the passed sequence,
--   which may change later. This is a shallow copy, so menu items are still referenced.
function text_menu:show_items(items)
  assert(#items > 0)
  self.active = true
  self.items = copy_seq(items)
  self.selection_index = 1
end

-- deactivate the menu and remove items
function text_menu:clear(items)
  self.active = false
  clear_table(self.items)
  self.selection_index = 0
end

-- handle navigation input
function text_menu:update()
  if self.active then
    if input:is_just_pressed(button_ids.up) then
      self:select_previous()
    elseif input:is_just_pressed(button_ids.down) then
      self:select_next()
    elseif input:is_just_pressed(button_ids.o) then
      self:confirm_selection()
    end
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
  self.items[self.selection_index].confirm_callback()
end

-- render menu, starting at top y, with text centered on x
function text_menu:draw(x, top)
  local y = top

  for i = 1, #self.items do
    -- for current selection, surround with "> <" like this: "> selected item <"
    local label = self.items[i].label
    local item_x = x

    if i == self.selection_index then
      if self.alignment == alignments.left then
        label = "> "..label
      elseif self.alignment == alignments.center then
        label = "> "..label.." <"
      end
    else
      -- if left aligned, move non-selected items to the right to align with selected item
       if self.alignment == alignments.left then
         item_x = item_x + 2 * character_width  -- "> " has 2 characters
       end
    end

    ui.print_aligned(label, item_x, y, self.alignment, self.text_color)
    y = y + character_height
  end
end

return text_menu
