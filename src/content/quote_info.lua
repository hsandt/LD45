require("engine/core/class")
require("engine/core/helper")

quote_types = {
  attack = 1,
  reply = 2
}

local quote_info = new_struct()

-- id: int
-- quote_type: quote_types
-- level: int
-- text: string
function quote_info:_init(id, quote_type, level, text)
  self.id = id
  self.type = quote_type
  self.level = level
  self.text = text
end

--#if log
function quote_info:_tostring()
  return "quote_info("..joinstr(", ", self.id, self.type, self.level, dump(self.text))..")"
end
--#endif

return quote_info
