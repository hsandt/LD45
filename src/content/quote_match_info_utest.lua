require("engine/test/bustedhelper")
local quote_match_info = require("content/quote_match_info")

describe('quote_match_info', function ()

  describe('_init', function ()
    it('should init a quote_match_info with id, type and text', function ()
      local q = quote_match_info(7, 2, 9, 1)
      assert.are_same({7, 2, 9, 1}, {q.id, q.attack_id, q.reply_id, q.power})
    end)
  end)

  describe('_tostring', function ()
    it('quote_match_info(7, 2, 9, 1) => "quote_match_info(7, 2, 9, 1)"', function ()
      local q = quote_match_info(7, 2, 9, 1)
      assert.are_equal("quote_match_info(7): 2 => 9 (power: 1)", q:_tostring())
    end)
  end)

end)
