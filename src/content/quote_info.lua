require("engine/core/class")

quote_types = enum {
  "attack",
  "reply"
}

local quote_info = new_struct()

-- id: int
-- quote_type: quote_types
-- level: int
-- text: string
function quote_info:_init(id, quote_type, level, text)
  self.id = id
  self.level = level
  self.quote_type = quote_type
  self.text = text
end

--#if log
function quote_info:_tostring()
  return "quote_info("..joinstr(", ", self.id, self.quote_type, self.level, dump(self.text))..")"
end
--#endif

return quote_info
