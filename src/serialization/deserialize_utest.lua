-- used at runtime, so may use for game helpers
require("test/bustedhelper_game")

local deserialize = require("serialization/deserialize")

describe('deserialize', function ()

  describe('text_from_mem', function ()

    it('should read length tag, then characters of a string byte by byte from memory', function ()
      pico8.poked_addresses = {
        [0x2000] = 5,
        [0x2001] = ord('h'),
        [0x2002] = ord('e'),
        [0x2003] = ord('l'),
        [0x2004] = ord('l'),
        [0x2005] = ord('o'),
      }

      assert.are_same({"hello", 0x2006}, {deserialize.text_from_mem(0x2000)})
    end)

  end)

  describe('text_table_to_mem', function ()

    it('should read each text with length tag and characters as bytes', function ()
      pico8.poked_addresses = {
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
        [0x200e] = 255
      }

      -- text_table_to_mem essentialy chains calls to text_from_mem, but it's funnier to test
      --  the final result than doing a bunch of assert.spy checks
      assert.are_same({"hello", "", "world!"}, deserialize.text_table_from_mem(0x2000, 0x2010))
    end)

  end)

end)
