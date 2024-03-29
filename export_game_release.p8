pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- Run this commandline script with:
-- $ pico8 -x export_cartridge.p8

-- It will export .bin and .p8.png for the current game release
-- Make sure to ./build_game release && ./install_cartridges.sh first
-- Note that it will not warn if cartridge is not found.
-- Paths are relative to PICO-8 carts directory.

-- #version
-- PICO-8 cannot read data/version.txt, so exceptionally set the version manually here
local version = "1.0"
local export_folder = "wit_fighter/v"..version.."_release"
local game_release_name = "wit_fighter_v"..version.."_release"
local rel_png_folder = game_release_name.."_png_cartridges"

cd(export_folder)

  local entry_cartridge = "wit_fighter.p8"

  local additional_main_cartridges_list = {
  }

  -- all main cartridges, including entry cartridge
  local main_cartridges_list = {entry_cartridge}
  for additional_main_cartridge in all(additional_main_cartridges_list) do
    add(main_cartridges_list, additional_main_cartridge)
  end

  local data_cartridges_list = {
    -- add additional language cartridges here
  }

  -- PNG

  -- prepare folder for png cartridges
  mkdir(rel_png_folder)

  -- data do not contain any code, so no need to adapt reload ".p8" -> ".p8.png"
  -- so just save them directly as png
  for cartridge_name in all(data_cartridges_list) do
    load(cartridge_name)
    save(rel_png_folder.."/"..cartridge_name..".png")
  end

  -- main cartridges need to be *adapted for PNG* for reload, so load those adapted versions
  --  to resave them as PNG
  -- (export_and_patch_cartridge_release.sh must have called pico-boots/scripts/adapt_for_png.py)
  -- the metadata label is used automatically for each
  cd("p8_for_png")

    for cartridge_name in all(main_cartridges_list) do
      load(cartridge_name)
      -- save as png (make sure to go one level up first since we are one level down)
      save("../"..rel_png_folder.."/"..cartridge_name..".png")
    end

  cd("..")

  printh("Resaved (adapted) cartridges as PNG in carts/"..export_folder.."/"..rel_png_folder)


  -- BIN & WEB

  -- load the original (not adapted for PNG) entry cartridge (titlemenu)
  -- this will serve as main entry point for the whole game
  load(entry_cartridge)

  -- concatenate cartridge names with space separator with a very simplified version
  --  of string.lua > joinstr_table that doesn't mind about adding an initial space
  local additional_cartridges_string = ""
  for cartridge_name in all(additional_main_cartridges_list) do
    additional_cartridges_string = additional_cartridges_string.." "..cartridge_name
  end
  for cartridge_name in all(data_cartridges_list) do
    additional_cartridges_string = additional_cartridges_string.." "..cartridge_name
  end


  -- BIN

  -- exports are done via EXPORT, and can use a custom icon
  --  instead of the .p8.png label
  -- icon is stored in builtin_data_titlemenu.p8,
  --  as a 16x16 square                               => -s 2 tiles wide
  --  with bottom-right cell at sprite (14, 14) = 238 => -i 238
  --  on pink (color 14) background                   => -c 14
  -- and most importantly we pass additional logic and data files as additional cartridges
  export(game_release_name..".bin "..additional_cartridges_string.." -i 238 -s 2 -c 14")
  printh("Exported binaries in carts/"..export_folder.."/"..game_release_name..".bin")


  -- WEB

  mkdir(game_release_name.."_web")
  -- Do not cd into game_release_name.."_web" because we want the additional cartridges to be accessible
  --  in current path. Instead, export directly into the _web folder
  -- Use custom template. It is located in plates/wit_fighter_template.html and copied into PICO-8 config dir plates
  --  in export_and_patch_cartridge_release.sh
  export(game_release_name.."_web/"..game_release_name..".html "..additional_cartridges_string.." -i 46 -s 2 -c 14 -p wit_fighter_template")
  printh("Exported HTML in carts/"..export_folder.."/"..game_release_name..".html")

cd("..")
