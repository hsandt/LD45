require("engine/test/bustedhelper")
local quote_info = require("content/quote_info")

describe('quote_info', function ()

  describe('_init', function ()
    it('should init a quote_info with id, type and text', function ()
      local q = quote_info(7, quote_types.attack, "aha!")
      assert.are_same({7, quote_types.attack, "aha!"}, {q.id, q.quote_type, q.text})
    end)
  end)

  describe('_tostring', function ()
    it('quote_info(7, quote_types.attack, "aha!") => "quote_info(7, 1, "aha!")"', function ()
      local q = quote_info(7, quote_types.attack, "aha!")
      assert.are_equal("quote_info(7, 1, \"aha!\")", q:_tostring())
    end)
  end)

end)
