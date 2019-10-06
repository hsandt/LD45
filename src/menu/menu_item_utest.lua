require("engine/test/bustedhelper")
local menu_item = require("menu/menu_item")

describe('menu_item', function ()

  describe('init', function ()
    it('should set label and target state', function ()
      local callback = function () end

      local item = menu_item("in-game", callback)

      assert.are_same({"in-game", callback}, {item.label, item.confirm_callback})
    end)
  end)

end)
