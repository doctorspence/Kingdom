#!/bin/bash
# Rebuilds the equipment pack: textures -> import -> models -> icons -> import -> definitions.
#   tools/eq_pipeline.sh [id1,id2]   (no argument = everything)
cd "$(dirname "$0")/.."
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
IDS="${1:-all}"
"$G" --headless --path . --script res://tools/gen_equipment_textures.gd 2>&1 | tail -1
"$G" --headless --path . --import 2>&1 | grep -i "error" | head
"$G" --headless --path . --script res://tools/build_equipment.gd -- "$IDS" 2>&1 | grep -i "error\|built\|tris"
"$G" --path . --resolution 320x200 --script res://tools/render_equipment_icons.gd -- "$IDS" 2>&1 | grep -i "error\|icons:"
"$G" --headless --path . --import 2>&1 | grep -i "error" | head
"$G" --headless --path . --script res://tools/build_equipment.gd -- "$IDS" 2>&1 | grep -i "error\|built"
