local quote_info = new_struct()

-- id: int
-- quote_type: quote_types
-- level: int
-- localized_string_id: int
function quote_info:init(id, quote_type, level, localized_string_id)
  self.id = id
  self.type = quote_type
  self.level = level
  self.localized_string_id = localized_string_id
end

--#if log
function quote_info:_tostring()
  return "("..(self.type == quote_types.attack and "A" or "R")..self.id..") Lv"..self.level..": localized string "..self.localized_string_id
end
--#endif

return quote_info
