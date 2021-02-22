require("test/bustedhelper_game")
local menu_helper = require("menu/menu_helper")

describe('menu_helper', function ()

  describe('clamp_text_with_ellipsis', function ()

    it('should return a string of max length or less as such', function ()
      assert.are_equal("just right size", menu_helper.clamp_text_with_ellipsis("just right size", 15))
    end)

    it('should return a string longer than max length by replacing last characters with 3 dots', function ()
      assert.are_equal("far ...", menu_helper.clamp_text_with_ellipsis("far too long", 7))
    end)

  end)

end)
