-- used offline, so just use engine helpers
require("engine/test/bustedhelper")

local serialize = require("serialization/serialize")

describe('serialize', function ()

  describe('text_to_mem', function ()

    it('should write length tag, then characters of a string byte by byte into memory', function ()
      local next_address = serialize.text_to_mem("hello", 0x2000)

      assert.are_equal(0x2006, next_address)
      assert.are_same({
          [0x2000] = ord('h'),
          [0x2001] = ord('e'),
          [0x2002] = ord('l'),
          [0x2003] = ord('l'),
          [0x2004] = ord('o'),
          [0x2005] = 0,
        }, pico8.poked_addresses)
    end)

    it('should assert if passing a non-string', function ()
      assert.has_error(function ()
        serialize.text_to_mem({})
      end)
    end)

    it('should assert if trying to write over the passed limit or beyond', function ()
      assert.has_error(function ()
        serialize.text_to_mem("hello", 0x2000, 0x2005)
      end)
    end)

    it('should not assert if trying to write just before the passed limit', function ()
      assert.has_no_errors(function ()
        serialize.text_to_mem("hello", 0x2000, 0x2006)
      end)
    end)

  end)

  describe('text_table_to_mem', function ()

    it('should write each text with length tag and characters as bytes, concatenated (as long as EOT byte is before limit)', function ()
      local next_address = serialize.text_table_to_mem({"hello", "", "world!"}, 0x2000, 0x200f)

      -- text_table_to_mem essentialy chains calls to text_to_mem, but it's funnier to test
      --  the final result than doing a bunch of assert.spy checks
      assert.are_equal(0x200f, next_address)
      assert.are_same({
          [0x2000] = ord('h'),
          [0x2001] = ord('e'),
          [0x2002] = ord('l'),
          [0x2003] = ord('l'),
          [0x2004] = ord('o'),
          [0x2005] = 0,
          [0x2006] = 0,  -- empty string serialized as "\0"
          [0x2007] = ord('w'),
          [0x2008] = ord('o'),
          [0x2009] = ord('r'),
          [0x200a] = ord('l'),
          [0x200b] = ord('d'),
          [0x200c] = ord('!'),
          [0x200d] = 0,
          [0x200e] = 4
        }, pico8.poked_addresses)
    end)

    it('should assert if trying to write over the passed limit for an individual string', function ()
      assert.has_error(function ()
        serialize.text_table_to_mem({"hello", "", "world!"}, 0x2000, 0x200d)
      end)
    end)

    it('should assert if trying to write over the passed limit with the EOT byte', function ()
      assert.has_error(function ()
        serialize.text_table_to_mem({"hello", "", "world!"}, 0x2000, 0x200e)
      end)
    end)

  end)

end)
