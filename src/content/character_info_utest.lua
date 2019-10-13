require("engine/test/bustedhelper")
local character_info = require("content/character_info")

describe('character_info', function ()

  describe('_init', function ()
    it('should init a character_info with id, name, level, initial quote ids', function ()
      local f_info = character_info(8, "employee")
      assert.are_same({8, "employee"},
        {f_info.id, f_info.name})
    end)
  end)

  describe('_tostring', function ()
    it('character_info(8, "employee") => "character_info(8, "employee")"', function ()
      local f_info = character_info(8, "employee")
      assert.are_equal("[character_info(8, \"employee\")]", f_info:_tostring())
    end)
  end)

end)
