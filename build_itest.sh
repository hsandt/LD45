#!/bin/bash

# Build a PICO-8 cartridge for the integration tests.
# This is essentially a proxy script for pico-boots/scripts/build_game.sh with the right parameters.

# Extra options are passed to build_cartridge.sh (with $@).
# This is useful in particular for --symbols.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_dir_path="$(dirname "$0")/build"

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
author="komehara"
title="wit fighter itests (all) v$version"
cartridge_stem="wit_fighter_itest_all"
config='itest'
# for now, we don't set `cheat` symbol to make it lighter, but it's still possible
# to test cheats in headless itests as busted preserves all (non-#pico8) code
symbols='assert,log,itest'

# Define build output folder from config
build_output_path="${build_dir_path}/v${version}_${config}"

# Build from itest main for all itests
"$picoboots_scripts_path/build_cartridge.sh"          \
  "$game_src_path" itest_main.lua itests              \
  -d "$data_path/data.p8" -M "$data_path/metadata.p8" \
  -a "$author" -t "$title"                            \
  -p "$build_output_path"                             \
  -o "${cartridge_stem}_v${version}"                  \
  -c "$config"                                        \
  -s "$symbols"                                       \
  --minify-level 3                                    \
  --unify ''
