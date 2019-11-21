local menu_helper = {}

function menu_helper.clamp_text_with_ellipsis(text, max_length)
  if #text > max_length then
    -- clamp, replace last chars with 3 dots
    return sub(text, 1, max_length - 3).."..."
  else
    -- use text as such
    return text
  end
end

return menu_helper
