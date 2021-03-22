-- used at runtime, so may use for game helpers
require("test/bustedhelper_game")

local deserialize = require("serialization/deserialize")

describe('deserialize', function ()

  describe('text_from_mem', function ()

    it('should read characters of a string byte by byte from memory, stopping at \\0', function ()
      pico8.poked_addresses = {
        [0x2000] = ord('h'),
        [0x2001] = ord('e'),
        [0x2002] = ord('l'),
        [0x2003] = ord('l'),
        [0x2004] = ord('o'),
        [0x2005] = 0
      }

      assert.are_same({"hello", 0x2006}, {deserialize.text_from_mem(0x2000)})
    end)

    it('should return nil, addr_start + 1 if it finds \\4', function ()
      pico8.poked_addresses = {
        [0x2000] = 4
      }

      assert.are_same({nil, 0x2001}, {deserialize.text_from_mem(0x2000)})
    end)

    it('should assert if it finds \\4 after some text (without \\0)', function ()
      pico8.poked_addresses = {
        [0x2000] = ord('h'),
        [0x2001] = ord('e'),
        [0x2002] = ord('l'),
        [0x2003] = ord('l'),
        [0x2004] = ord('o'),
        [0x2005] = 4
      }

      assert.has_error(function ()
        deserialize.text_from_mem(0x2000)
      end)
    end)

    it('should assert if it doesn\'t find \\0 before the limit, even if exactly on the limit' , function ()
      pico8.poked_addresses = {
        [0x2000] = ord('h'),
        [0x2001] = ord('e'),
        [0x2002] = ord('l'),
        [0x2003] = ord('l'),
        [0x2004] = ord('o'),
        [0x2005] = 0
      }

      assert.has_error(function ()
        deserialize.text_from_mem(0x2000, 0x2005)
      end)
    end)

  end)

  describe('text_table_to_mem', function ()

    it('should read each text with length tag and characters as bytes', function ()
      pico8.poked_addresses = {
        [0x2000] = ord('h'),
        [0x2001] = ord('e'),
        [0x2002] = ord('l'),
        [0x2003] = ord('l'),
        [0x2004] = ord('o'),
        [0x2005] = 0,
        [0x2006] = 0,
        [0x2007] = ord('w'),
        [0x2008] = ord('o'),
        [0x2009] = ord('r'),
        [0x200a] = ord('l'),
        [0x200b] = ord('d'),
        [0x200c] = ord('!'),
        [0x200d] = 0,
        [0x200e] = 4
      }

      -- text_table_to_mem essentialy chains calls to text_from_mem, but it's funnier to test
      --  the final result than doing a bunch of assert.spy checks
      assert.are_same({"hello", "", "world!"}, deserialize.text_table_from_mem(0x2000, 0x2010))
    end)

  end)

  it('should assert if it doesn\'t find \\0 followed by \\4 before the limit, even if exactly on the limit' , function ()
    pico8.poked_addresses = {
      [0x2000] = ord('h'),
      [0x2001] = ord('e'),
      [0x2002] = ord('l'),
      [0x2003] = ord('l'),
      [0x2004] = ord('o'),
      [0x2005] = 0,
      [0x2006] = 4
    }

    assert.has_error(function ()
      deserialize.text_table_from_mem(0x2000, 0x2006)
    end)
  end)

end)
