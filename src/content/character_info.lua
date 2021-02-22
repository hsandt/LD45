local character_info = new_struct()

-- id: int
-- name: string      character name
-- sprite_id: int    character sprite id used to retrieve sprite_data in visual data
function character_info:init(id, name, sprite_id)
  self.id = id
  self.name = name
  self.sprite_id = sprite_id
end

--#if log
function character_info:_tostring()
  return "[character_info("..joinstr(", ", self.id, dump(self.name))..")]"
end
--#endif

return character_info
