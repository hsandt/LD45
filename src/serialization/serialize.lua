local serialize = {}

-- Write text data into memory, starting at addr_start
-- First write a tag containing the text length in 1 byte. 255 is reserved to indicate
-- that this was the last string we serialized (see text_table_to_mem), so text must not
-- be longer than 254 characters.
-- Then write the actual text's characters byte by byte.
-- Optional addr_exclusive_limit will make sure we assert (return if not #assert)
--  if we were going to write on addr_exclusive_limit or beyond
--  (it is exclusive so you can pass 0x3000 rather than 0x2fff)
-- Return address of next free address, just after the last written address
-- Thanks for doc1oo
function serialize.text_to_mem(text, addr_start, addr_exclusive_limit)
  assert(type(text) == "string", "expected text to be string, but it is a "..type(text))

  if #text > 254 then
    assert(false, "text has length "..#text..", max is 254 (255 reserved)")
--[[#pico8
--#ifn assert
    return nil
--#endif
--#pico8]]
  end

  -- addr_start + #text gives the address *just after* the last written byte, so >
  if addr_exclusive_limit and addr_start + #text > addr_exclusive_limit then
    assert(false, "writing from addr_start: "..addr_start.." over #text: "..#text..
      ", would write over addr_exclusive_limit: "..addr_exclusive_limit..", stop.")
--[[#pico8
--#ifn assert
    return nil
--#endif
--#pico8]]
  end

  -- write length tag
  poke(addr_start, #text)

  -- write character bytes
  -- addr_start contains length tag, so text effectively starts at addr_start + 1
  local next_addr = addr_start + 1
  for i = 1, #text do
    local c = sub(text, i, i)
    local byte = ord(c)
    poke(next_addr, byte)
    next_addr = next_addr + 1
  end

  return next_addr
end

-- Write sequence of texts into memory, by chaining text_to_mem writes to effectively
--  concatenate all the text strings (with tag) into memory.
-- Return address of next free address, just after the last written address
function serialize.text_table_to_mem(text_table, addr_start, addr_exclusive_limit)
  local next_addr = addr_start
  for text in all(text_table) do
    serialize.text_to_mem(text, next_addr, addr_exclusive_limit)
    -- advance to start of next text
    -- we've used 1 byte for the length tag, so + 1
    next_addr = next_addr + #text + 1
  end
  return next_addr
end

return serialize
