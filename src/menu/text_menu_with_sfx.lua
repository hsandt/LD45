require("engine/core/class")

local text_menu = require("menu/text_menu")
local audio_data = require("resources/audio_data")

local text_menu_with_sfx = new_class(text_menu)

function text_menu_with_sfx:on_selection_changed()  -- override
  sfx(audio_data.sfx.menu_select)
end

function text_menu_with_sfx:on_confirm_selection()  -- override
  sfx(audio_data.sfx.menu_confirm)
end

return text_menu_with_sfx
