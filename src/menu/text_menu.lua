require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/render/color")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

--[[
Class representing a menu with labels and arrow-based scrolling navigation

External references
  app               gameapp       game app, provided to ease object access in item callbacks

Instance parameters
  items_count_per_page  int         number of items displayed per page
  alignment             alignments  text alignment to use for item display
  text_color            colors      item text color

Instance dynamic parameters
  items             {menu_item}   sequence of items to display

Instance state
  active           bool           if true, the text menu is shown and receives input
  selection_index  int            index of the item currently selected
--]]

local text_menu = new_class()
function text_menu:_init(app, items_count_per_page, alignment, text_color)
  -- external references
  self.app = app

  -- parameters
  self.items_count_per_page = items_count_per_page
  self.alignment = alignment
  self.text_color = text_color

  -- dynamic parameters (mostly set once, but may change in some usage cases)
  self.items = {}

  -- state
  self.active = false
  self.selection_index = 0
end

-- idea: make a uniform_action_menu which takes a single function,
--   and one generic parameter (or more) per item, and always calls
--   the function(parameter) on confirm, since most menus apply the same function

-- Activate the menu, fill items with given sequence and initialise selection
--
-- We deep copy the sequence content to avoid referencing the passed sequence,
--   which may change later.
function text_menu:show_items(items)
  assert(#items > 0)
  self.active = true

  -- deep copy of menu items to be safe on future change
  clear_table(self.items)
  for item in all(items) do
    add(self.items, item:copy())
  end

  -- we prefer direct calls to change_selection() because the latter would not call
  --   try_select_callback if the index was already 1 on the previously shown items
  --   (and we didn't clear), and we don't want to call on_selection_changed either
  self.selection_index = 1
  self:try_select_callback(1)
end

-- deactivate the menu and remove items
function text_menu:clear(items)
  self.active = false
  clear_table(self.items)
  -- raw set instead of self:set_selection/change_selection(0) which have side effects
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

-- like set_selection, but also calls on_selection_changed
function text_menu:change_selection(index)
  if self.selection_index ~= index then
    self.selection_index = index
    self:try_select_callback(index)
    self:on_selection_changed()
  end
end

function text_menu:select_previous()
  -- clamp selection
  if self.selection_index > 1 then
    self:change_selection(self.selection_index - 1)
  end
end

function text_menu:select_next()
  -- clamp selection
  if self.selection_index < #self.items then
    self:change_selection(self.selection_index + 1)
  end
end

-- apply select callback for this item if any
-- unlike on_selection_changed, it is item-specific
function text_menu:try_select_callback(index)
  local select_callback = self.items[index].select_callback
  if select_callback then
    select_callback(self.app)
  end
end

function text_menu:on_selection_changed()  -- virtual
end

function text_menu:confirm_selection()
  -- just deactivate menu, so we can reuse the items later if menu is static
  -- (by setting self.active = true), else next time show_items to refill the items
  self.active = false

  -- we must call the callback *after* deactivating the text_menu, in case it immediately
  -- shows new choices itself, so it is not hidden after filling the items
  self.items[self.selection_index].confirm_callback(self.app)

  -- callback
  self:on_confirm_selection()
end

function text_menu:on_confirm_selection()  -- virtual
end

-- render menu, starting at top y, with text centered on x
function text_menu:draw(x, top)
  if #self.items == 0 then
    return
  end

  assert(self.selection_index > 0, "self.selection_index is "..self.selection_index..", should be > 0")

  local y = top

  -- identify which page is currently shown from the current selection
  -- unlike other indices in Lua, page starts at 0
  local page_index0 = flr((self.selection_index - 1) / self.items_count_per_page)
  local first_index0 = page_index0 * self.items_count_per_page
  local last_index0 = min(first_index0 + self.items_count_per_page - 1, #self.items - 1)
  for i = first_index0 + 1, last_index0 + 1 do
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
