#!/bin/bash

# This is essentially a proxy script for pico-boots/scripts/build_cartridge.sh.
# The serialize cartridge is only run on dev side, to pack string data into a separate data cartridge's
# __map__ area for building into game cartridge via p8tool.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_dir_path="$(dirname "$0")/build"

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
author="komehara"
cartridge_stem="wit_fighter_serialize"
title="wit fighter serialize v$version"

help() {
  echo "Build a PICO-8 cartridge for serialization with the passed config."
  usage
}

usage() {
  echo "Usage: build_game.sh [CONFIG]

ARGUMENTS
  CONFIG                    Build config. Determines defined preprocess symbols.
                            (default: 'debug')

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -* )    # unknown option
      echo "Unknown option: '$1'"
      usage
      exit 1
      ;;
    * )     # store positional argument for later
      positional_args+=("$1")
      shift # past argument
      ;;
  esac
done

if ! [[ ${#positional_args[@]} -ge 0 && ${#positional_args[@]} -le 1 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 0 or 1."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

if [[ ${#positional_args[@]} -ge 1 ]]; then
  config="${positional_args[0]}"
fi

# Define build output folder from config
build_output_path="${build_dir_path}/v${version}_${config}"

# Define symbols from config
symbols=''

# below, we put tostring together with assert because some asserts
# use joinstr and engine only requires string_join in common if #tostring

# serialize code is very simple though, so we can probably just always use debug

if [[ $config == 'debug' ]]; then
  symbols='assert,tostring,log'
fi

# Build from serialize_main
# data_serialize.p8 should contain a sprite alphabet, where sprite index = ord(character),
# just so we can read uncompressed directly on the map!
"$picoboots_scripts_path/build_cartridge.sh"             \
  "$game_src_path" serialize_main.lua                    \
  -d "$data_path/data_serialize.p8"                      \
  -a "$author" -t "$title"                               \
  -p "$build_output_path"                                \
  -o "${cartridge_stem}"                                 \
  -c "$config"                                           \
  -s "$symbols"                                          \
  --minify-level 3                                       \
  --unify ''

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Build failed, STOP."
  exit 1
fi
