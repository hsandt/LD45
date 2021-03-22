local serialize = {}

-- Write text data into memory, starting at addr_start
-- Format: [string][\0]
-- String characters are written byte by byte.
-- \0 is a terminating character as in C, and allows to us to know the string ends here.
-- Optional addr_exclusive_limit will make sure we assert (return if not #assert)
--  if we were going to write on addr_exclusive_limit or beyond
--  (it is exclusive so you can pass 0x3000 to stop at 0x2fff)
-- Return address of next free address (just after \0)
-- Thanks for doc1oo
function serialize.text_to_mem(text, addr_start, addr_exclusive_limit)
  assert(type(text) == "string", "expected text to be string, but it is a "..type(text))

  -- addr_start + #text gives the address *just after* the last written byte, so >
  if addr_exclusive_limit and addr_start + #text >= addr_exclusive_limit then
--#if assert
    assert(false, "writing from addr_start: "..addr_start.." over #text: "..#text..
      ", would write over addr_exclusive_limit: "..addr_exclusive_limit..", stop.")
--#endif
--[[#pico8
--#ifn assert
    return  -- nil
--#endif
--#pico8]]
  end

  -- write character bytes
  local next_addr = addr_start
  for i = 1, #text do
    local c = sub(text, i, i)
    local byte = ord(c)
    poke(next_addr, byte)
    next_addr = next_addr + 1
  end

  -- write terminating \0 (in most cases memory will already be 0,
  --  but overwrite just to be sure)
  poke(next_addr, 0)

  -- any next string would start right after \0
  return next_addr + 1
end

-- Write sequence of texts into memory, by chaining text_to_mem writes to effectively
--  concatenate all the text strings (with \0) into memory.
-- Finish by adding an End of Transmission (\4) byte so deserialize function knows when
--  the last text has been parsed (more reliable than yet another \0 which could just
--  be an empty string).
-- Return address of next free address, just after the last written address (containing \4)
function serialize.text_table_to_mem(text_table, addr_start, addr_exclusive_limit)
  local next_addr = addr_start
  for text in all(text_table) do
    -- serialize text and retrieve next address
    -- do not compute it yourself from text length! this allows us to detect reaching
    --  limit which would return nil
    next_addr = serialize.text_to_mem(text, next_addr, addr_exclusive_limit)
    if not next_addr then
      -- if #assert when we must already have asserted in text_to_mem, no need to re-assert
      return  -- nil
    end
  end

-- addr_start + #text gives the address *just after* the last written byte, so >
  if addr_exclusive_limit and next_addr >= addr_exclusive_limit then
--#if assert
    assert(false, "writing text strings worked, but end of transmission byte would just be on addr_exclusive_limit: "..
      addr_exclusive_limit..", stop.")
--#endif
--[[#pico8
--#ifn assert
    return  -- nil
--#endif
--#pico8]]
  end

  -- write end of transmission \4
  poke(next_addr, 4)

  -- any other string/table would start right after \4
  return next_addr + 1
end

return serialize
