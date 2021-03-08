require("engine/test/bustedhelper")

local serialize = require("serialization/serialize")

describe('serialize', function ()

  describe('text_to_mem', function ()

    it('should write length tag, then characters of a string byte by byte into memory', function ()
      local next_address = serialize.text_to_mem("hello", 0x2000)

      assert.are_equal(0x2006, next_address)
      assert.are_same({
          [0x2000] = 5,
          [0x2001] = ord('h'),
          [0x2002] = ord('e'),
          [0x2003] = ord('l'),
          [0x2004] = ord('l'),
          [0x2005] = ord('o'),
        }, pico8.poked_addresses)
    end)

    it('should assert if trying to write a string over 254 chars', function ()
      local long_string = ""
      for i = 1, 255 do
        long_string = long_string.."|"
      end
      assert.has_error(function ()
        serialize.text_to_mem(long_string, 0x2000)
      end)
    end)

    it('should assert if trying to write over the passed limit or beyond', function ()
      assert.has_error(function ()
        serialize.text_to_mem("hello", 0x2000, 0x2004)
      end)
    end)

    it('should not assert if trying to write just before the passed limit', function ()
      assert.has_no_errors(function ()
        serialize.text_to_mem("hello", 0x2000, 0x2005)
      end)
    end)

  end)

  describe('text_table_to_mem', function ()

    it('should write each text with length tag and characters as bytes, concatenated', function ()
      local next_address = serialize.text_table_to_mem({"hello", "", "world!"}, 0x2000)

      -- text_table_to_mem essentialy chains calls to text_to_mem, but it's funnier to test
      --  the final result than doing a bunch of assert.spy checks
      assert.are_equal(0x200e, next_address)
      assert.are_same({
          [0x2000] = 5,
          [0x2001] = ord('h'),
          [0x2002] = ord('e'),
          [0x2003] = ord('l'),
          [0x2004] = ord('l'),
          [0x2005] = ord('o'),
          [0x2006] = 0,
          [0x2007] = 6,
          [0x2008] = ord('w'),
          [0x2009] = ord('o'),
          [0x200a] = ord('r'),
          [0x200b] = ord('l'),
          [0x200c] = ord('d'),
          [0x200d] = ord('!'),
        }, pico8.poked_addresses)
    end)

  end)

end)
