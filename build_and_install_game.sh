#!/bin/bash
root_dir_path="$(dirname "$0")"
"$root_dir_path/build_game.sh" $1
"$root_dir_path/install_single_cartridge.sh" $1
