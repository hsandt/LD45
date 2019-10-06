require("engine/core/class")

-- a single menu item leading to a gamestate on confirm
local menu_item = new_struct()

-- label: string               text displayed in the menu
-- confirm_callback: function  callback applied when confirming item selection
function menu_item:_init(label, confirm_callback)
  self.label = label
  self.confirm_callback = confirm_callback
end

return menu_item
