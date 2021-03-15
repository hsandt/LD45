local deserialize = require("serialization/deserialize")
--#if busted
local text_data = require("resources/text_data")
--#endif

-- members
-- strings   [string]   sequence of localized strings, indexed by localized_string_id
local localizer = singleton(function (self)
  -- to spare characters we don't init localizer.strings to nil nor {}
  --  so make sure to call load_all_strings very early in your main
  --  (gameapp.on_pre_start is a good choice)
end)

function localizer:load_all_strings()
  -- load all localized strings stored in __map__ data from a dedicated cartridge
  -- having a separate cartridge allows us to add more languages later
  -- TODO: to support multi-cartridge we need to build and install game into
  --  carts folder every time. Currently we don't and only need one language,
  --  so I just manually copied __map__ content into data.p8 so we don't need
  --  to reload anything
  -- reload(0x2000, 0x2000, 0x1000, "text_data_en.p8")
  self.strings = deserialize.text_table_from_mem(0x2000, 0x3000)
end

function localizer:get_string(localized_string_id)
--#if busted
  return text_data.strings[localized_string_id]
--#endif
--[[#pico8
  return self.strings[localized_string_id]
--#pico8]]
end

return localizer
