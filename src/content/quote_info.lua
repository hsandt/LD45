local quote_info = new_struct()

-- id: int
-- quote_type: quote_types
-- level: int
-- text: string
function quote_info:init(id, quote_type, level, text)
  self.id = id
  self.type = quote_type
  self.level = level
  self.text = text
end

--#if log
function quote_info:_tostring()
  return "("..(self.type == quote_types.attack and "A" or "R")..self.id..") Lv"..self.level..": \""..self.text.."\""
end
--#endif

return quote_info
