require("engine/test/bustedhelper")
local fighter_progression = require("progression/fighter_progression")

local fighter_info = require("content/fighter_info")

require("engine/debug/logging")

describe('fighter_progression', function ()

  describe('_init', function ()
    it('should init a fighter_progression', function ()
      local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})
      local f_progression = fighter_progression(character_types.ai, mock_fighter_info)
      assert.are_same({
          character_types.ai,
          4,
          5,
          {11, 27},
          {12, 28},
          {2, 4}
        },
        {
          f_progression.character_type,
          f_progression.level,
          f_progression.max_hp,
          f_progression.known_attack_ids,
          f_progression.known_reply_ids,
          f_progression.known_quote_match_ids
        })
      assert.are_equal(mock_fighter_info, f_progression.fighter_info)
    end)
  end)

end)
