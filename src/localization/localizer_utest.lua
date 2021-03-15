require("test/bustedhelper_game")

local localizer = require("localization/localizer")

local deserialize = require("serialization/deserialize")
local text_data = require("resources/text_data")

describe('localizer', function ()

  after_each(function ()
    -- reset singleton
    localizer:init()
  end)

  describe('load_all_strings', function ()

    setup(function ()
      stub(deserialize, "text_table_from_mem", function (addr_start, addr_exclusive_limit)
        -- a absurd example when the sequence is precisely the start and limit address
        --  although it doesn't make sense
        return {addr_start, addr_exclusive_limit}
      end)
    end)

    teardown(function ()
      deserialize.text_table_from_mem:revert()
    end)

    after_each(function ()
      deserialize.text_table_from_mem:clear()
    end)

    it('should deserialize all strings in memory and store them in strings member', function ()
      localizer:load_all_strings()

      assert.are_same({0x2000, 0x3000}, localizer.strings)
    end)

  end)

  describe('get_string', function ()

    it('should deserialize all strings in memory and store them in strings member', function ()
      -- this is the utest for the busted code
      assert.are_equal(text_data.strings[2], localizer:get_string(2))

      -- below is the true utest for #pico8
      -- you can temporarily comment out busted code and move pico8 code
      --  outside #pico8 block, as well as comment out busted utest above and
      --  uncomment code below to test the pico8 implementation
      --[[
      localizer.strings = {
        "a",
        "b",
        "c",
      }

      assert.are_equal("b", localizer:get_string(2))
      --]]
    end)

  end)

end)
