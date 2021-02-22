require("test/bustedhelper_game")
local quote_info = require("content/quote_info")

describe('quote_info', function ()

  describe('init', function ()
    it('should init a quote_info with id, type, level, text', function ()
      local q = quote_info(7, quote_types.attack, 3, "aha!")
      assert.are_same({7, quote_types.attack, 3, "aha!"}, {q.id, q.type, q.level, q.text})
    end)
  end)

  describe('_tostring', function ()
    it('quote_info(7, quote_types.attack, 3, "aha!") => "(A7) Lv3: "aha!""', function ()
      local q = quote_info(7, quote_types.attack, 3, "aha!")
      assert.are_equal("(A7) Lv3: \"aha!\"", q:_tostring())
    end)
  end)

end)
