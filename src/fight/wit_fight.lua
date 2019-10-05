-- wit fight: in-game gamestate for fighting an opponent
local wit_fight = derived_class(gamestate)

wit_fight.type = ':wit_fight'

function wit_fight:_init()
end

function wit_fight:on_enter()
end

function wit_fight:on_exit()
end

function wit_fight:update()
end

function wit_fight:render()
  self:draw_background()
  self:draw_characters()
  self:draw_hud()
end

function wit_fight:draw_background()
  -- wall
  rectfill(0, 0, 127, 127, colors.dark_gray)
  -- floor
  rectfill(0, 51, 103, 127, colors.light_gray)
  line(0, 50, 104, 50, colors.black)
  line(104, 50, 104, 127, colors.black)
  -- upper stairs
  -- lower stairs
end

function wit_fight:draw_characters()

end

function wit_fight:draw_hud()

end

return wit_fight
