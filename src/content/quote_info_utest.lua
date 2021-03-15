require("test/bustedhelper_game")
local quote_info = require("content/quote_info")

describe('quote_info', function ()

  describe('init', function ()
    it('should init a quote_info with id, type, level, localized_string_id', function ()
      local q = quote_info(7, quote_types.attack, 3, 11)
      assert.are_same({7, quote_types.attack, 3, 11}, {q.id, q.type, q.level, q.localized_string_id})
    end)
  end)

  describe('_tostring', function ()
    it('quote_info(7, quote_types.attack, 3, 11) => "(A7) Lv3: localized string 11"', function ()
      local q = quote_info(7, quote_types.attack, 3, 11)
      assert.are_equal("(A7) Lv3: localized string 11", q:_tostring())
    end)
  end)

end)
