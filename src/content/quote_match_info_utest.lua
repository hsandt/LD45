require("engine/test/bustedhelper")
local quote_match_info = require("content/quote_match_info")

describe('quote_match_info', function ()

  describe('_init', function ()
    it('should init a quote_match_info with id, type and text', function ()
      local q = quote_match_info(2, 9)
      assert.are_same({2, 9}, {q.attack_id, q.reply_id})
    end)
  end)

  describe('_tostring', function ()
    it('quote_match_info(7, quote_types.attack, 3, "aha!") => "quote_match_info(7, 1, 3, "aha!")"', function ()
      local q = quote_match_info(2, 9)
      assert.are_equal("quote_match_info(2, 9)", q:_tostring())
    end)
  end)

end)
