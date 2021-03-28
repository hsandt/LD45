-- main entry file for serialize
-- much simplified from main game cartridge, since we just serialize data into cartridge memory, save and exit

-- we must require engine/pico8/api at the top of our main.lua, so API bridges apply to all modules
require("engine/pico8/api")
require("engine/common")
require("common_serialize")

--#if log
local logging = require("engine/debug/logging")
--#endif

local text_data = require("resources/text_data")
local serialize = require("serialization/serialize")

--#if log
-- start logging before app in case we need to read logs about app start itself
logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)

logging.file_log_stream.file_prefix = "wit_fighter"

-- clear log file on new game session (or to preserve the previous log,
-- you could add a newline and some "[SESSION START]" tag instead)
logging.file_log_stream:clear()

logging.logger.active_categories = {
  -- engine
  ['default'] = true,
}
--#endif

-- copy text character bytes into __map__ memory, which is unused in Wit Fighter
-- the range of unshared map memory is 0x2000-0x2fff, 0x3000 is the exclusive limit
serialize.text_table_to_mem(text_data.strings, 0x2000, 0x3000)

save("wit_fighter_text_data_en_with_code.p8")
