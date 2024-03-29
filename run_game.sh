#!/bin/bash

# Run game cartridge with PICO-8 executable
# Must be called after build script
# Usage: run_game.sh config [extra]
#   config            build config (e.g. 'debug' or 'release')

# Any extra arguments are passed to pico8

# Configuration: paths
data_path="$(dirname "$0")/data"

# Configuration: cartridge
cartridge_stem="wit_fighter"
version=`cat "$data_path/version.txt"`

# shift allows to pass extra arguments as $@
config="$1"; shift

run_cmd="pico8 -run build/v${version}_${config}/${cartridge_stem}.p8 -screenshot_scale 4 -gif_scale 4 $@"

# Support UNIX platforms without gnome-terminal by checking if the command exists
# If you `reload.sh` the game, the separate terminal allows you to keep watching the program output,
# but depending on your work environment it may not be needed (it is useful with Sublime Text as the output
# panel would get cleared on reload).
# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash gnome-terminal 2>/dev/null; then
  # gnome-terminal exists
  echo "> gnome-terminal -- bash -x -c \"$run_cmd\""
  gnome-terminal -- bash -x -c "$run_cmd"
else
  echo "> $run_cmd"
  bash -c "$run_cmd"
fi
