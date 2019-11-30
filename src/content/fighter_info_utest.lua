require("engine/test/bustedhelper")
local fighter_info = require("content/fighter_info")

describe('fighter_info', function ()

  describe('_init', function ()
    it('should init a fighter_info with id, name, level, initial quote ids', function ()
      local f_info = fighter_info(8, 3, 4, 5, {11, 27}, {12, 28})
      assert.are_same({8, 3, 4, 5, {11, 27}, {12, 28}},
        {f_info.id, f_info.character_info_id, f_info.initial_level, f_info.initial_max_hp, f_info.initial_attack_ids, f_info.initial_reply_ids})
    end)
  end)

  describe('_tostring', function ()
    it('fighter_info(8, 3, 4, {11, 27}) => "fighter_info(8, 3)"', function ()
      local f_info = fighter_info(8, 3, 4, 5, {11, 27}, {12, 28})
      assert.are_equal("[fighter_info(8, 3)]", f_info:_tostring())
    end)
  end)

end)
