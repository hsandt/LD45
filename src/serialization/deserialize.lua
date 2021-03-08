local deserialize = {}

-- Read text data from memory, starting at addr_start
-- First read the tag containing the text length in 1 byte. 255 is reserved to indicate
-- that this was the last string we serialized (see text_table_to_mem), so if it is found,
-- return nothing immediately to indicate that we reached the end of a serialization stream.
-- Otherwise, read the actual text's characters byte by byte.
-- Then return (deserialized text string, next address after last read)
function deserialize.text_from_mem(addr_start)
  -- read length tag
  -- TODO: prefer \0 ending pattern, can allow strings longer than 254
  local text_length = peek(addr_start)
  if text_length == 255 then
    return -- nil, nil
  end

  local text = ""

  -- read character bytes
  -- addr_start contains length tag, so text effectively starts at addr_start + 1
  local next_addr = addr_start + 1
  for i = 1, text_length do
    local byte = peek(next_addr)
    local c = chr(byte)
    text = text..c
    next_addr = next_addr + 1
  end

  return text, next_addr
end

-- Read sequence of texts from memory, by chaining text_from_mem reads to effectively
--  extract all the text strings from memory.
-- Return address of next free address, just after the last written address
-- addr_exclusive_limit avoids infinite loop in case we forgot to put 255
-- (will be replaced will null-termination convention)
function deserialize.text_table_to_mem(addr_start, addr_exclusive_limit)
  local text_sequence = {}

  local next_addr = addr_start
  while true do
    local text
    if next_addr >= addr_exclusive_limit then
      break
    end
    text, next_addr = deserialize.text_from_mem(next_addr)
    if not text then
      break
    end
    add(text_sequence, text)
  end

  return text_sequence
end

return deserialize
