local gamestate = require("engine/application/gamestate")

local painter = require("render/painter")
local visual_data = require("resources/visual_data")
local character = require("story/character")

local adventure = derived_class(gamestate)

adventure.type = ':adventure'

function adventure:_init(app)
  gamestate._init(self, app)

  self.pc = character(visual_data.sprites.pc, visual_data.pc_sprite_pos, visual_data.rel_bubble_tail_pos_pc)
end

function adventure:on_enter()
  self.app.managers[':dialogue']:add_speaker(self.pc.speaker)

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  self.app.managers[':dialogue'].should_show_bottom_box = true

  self.app:start_coroutine(self.play_intro, self)
end

function adventure:on_exit()
  self.app.managers[':dialogue'].should_show_bottom_box = false
end

function adventure:update()
end

function adventure:render()
  painter.draw_background()
  self.pc:draw()
end

function adventure:play_intro()
  self.app:yield_delay_s(2)
  self.app.managers[':dialogue'].current_bottom_text = 'it company "browsing solutions"\nmain building'
  self.app:yield_delay_s(4)
  self.app.managers[':dialogue'].current_bottom_text = nil
  self.app:yield_delay_s(2)
  self.pc.speaker:say("ok, let's sum up")
  self.app:yield_delay_s(2)
  self.pc.speaker:say("1. i need funding to organize a hackathon.")
  self.app:yield_delay_s(2)
  self.pc.speaker:say("2. my sister is the ceo of this company and could be my sponsor. she's working at the 20th floor.")
  self.app:yield_delay_s(2)
  self.pc.speaker:say("3. i don't want be to seen so i'm avoiding the elevator and taking those seemingly endless stairs")
  self.app:yield_delay_s(4)
  self.pc.speaker:say("seems good so far. what could go wrong?")
  self.app:yield_delay_s(4)
  self.app.managers[':dialogue'].current_bottom_text = 'the end'
end

return adventure
