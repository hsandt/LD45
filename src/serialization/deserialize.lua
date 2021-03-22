local deserialize = {}

-- Read text data from memory, starting at addr_start
-- If the End of Transmission byte \4 is encountered, return nil (actually nothing)
--  to indicate that we reached the end of a serialization stream.
-- Otherwise, read the actual text's characters byte by byte.
-- This also works if \0 is immediately encountered (just return empty string).
-- Then return (deserialized text string, next address after last read)
function deserialize.text_from_mem(addr_start, addr_exclusive_limit)
  local text = ""

  -- read character bytes
  local next_addr = addr_start
  while true do
    if addr_exclusive_limit and next_addr >= addr_exclusive_limit then
      -- we crossed the limit (we may even be a little further, but that's OK)
--#if assert
      assert(false, "writing from addr_start: "..addr_start.." until next_addr which reached "..
            "addr_exclusive_limit: "..addr_exclusive_limit..", stop.")
--#endif
--[[#pico8
--#ifn assert
      -- stop and return what we've found so far, but next address as nil
      --  to show we shouldn't go on
      return text, nil
--#endif
--#pico8]]
    end

    local byte = peek(next_addr)
    if byte == 0 then
      -- \0 encountered, end of string reached. Next address will be just after that.
      return text, next_addr + 1
    elseif byte == 4 then
      -- \4 encountered, end of transmission reached
      -- This should only happen for the first character, as any string should
      --  end with \0 and only the next call to text_from_mem should find \4
      -- Next address will be just after that.
      -- (normally we only text_table_from_mem should be aware of \4, but
      --  then it should do a peek, and if not \4 call text_from_mem which would do peek again)
      assert(#text == 0, "\\4 encountered immediately after some text, missing terminating byte \\0")
      return nil, next_addr + 1
    end

    -- read the byte as a character, append to current deserialized text and go on
    local c = chr(byte)
    text = text..c
    next_addr = next_addr + 1
  end
end

-- Read sequence of texts from memory, by chaining text_from_mem reads to effectively
--  extract all the text strings from memory.
-- Return (deserialized text sequence, next address after last read)
-- addr_exclusive_limit avoids infinite loop in case we meet no End of Transmission (\4)
function deserialize.text_table_from_mem(addr_start, addr_exclusive_limit)
  local text_sequence = {}

  local next_addr = addr_start
  while true do
    local text
    text, next_addr = deserialize.text_from_mem(next_addr, addr_exclusive_limit)

    if not text then
      -- we've reached EOT (\4), return deserialized text sequence and next address
      -- this is the expected control path
      break
    end

    add(text_sequence, text)

    if not next_addr then
      -- if #assert when we must already have asserted in text_to_mem, no need to re-assert
      -- we will return deserialized text sequence and nil
      break
    end
  end

  return text_sequence, next_addr
end

return deserialize
