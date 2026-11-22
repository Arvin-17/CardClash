#!/usr/bin/env bash
# Play CardClash.
#
#   ./play.sh                          # find Godot, import the project if needed, start the game
#   GODOT=/path/to/Godot ./play.sh     # use a specific Godot binary
#
# Why this exists: a fresh clone has never been imported (game/.godot/ is not in git), and
# running the game directly doesn't import it, so the scripts and fonts fail to load. This
# script imports first (and again after a `git pull` changes files), then starts the game.
set -euo pipefail
cd "$(dirname "$0")"
NEED_MAJOR=4
NEED_MINOR=7

find_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		echo "$GODOT"
		return 0
	fi
	local cmd
	for cmd in godot godot4 Godot; do
		if command -v "$cmd" >/dev/null 2>&1; then
			command -v "$cmd"
			return 0
		fi
	done
	# macOS: Godot.app doesn't put a `godot` command on the PATH.
	local app
	for app in /Applications/Godot*.app "$HOME"/Applications/Godot*.app "$HOME"/Downloads/Godot*.app; do
		if [[ -x "$app/Contents/MacOS/Godot" ]]; then
			echo "$app/Contents/MacOS/Godot"
			return 0
		fi
	done
	# Linux: the download is a single executable.
	local bin
	for bin in "$HOME"/Downloads/Godot_v4*_linux*.x86_64 "$HOME"/.local/bin/Godot_v4*_linux*.x86_64; do
		if [[ -x "$bin" ]]; then
			echo "$bin"
			return 0
		fi
	done
	return 1
}

if ! GODOT_BIN="$(find_godot)"; then
	cat >&2 <<'MSG'
Godot 4.7 isn't installed (or this script can't find it).

  macOS:   download Godot 4.7 from https://godotengine.org/download/macos/ , unzip it,
           and drag Godot.app into Applications. Or: brew install --cask godot
  Linux:   download Godot 4.7 from https://godotengine.org/download/linux/ and put the
           Godot_v4.7...x86_64 file in ~/Downloads or ~/.local/bin (or on your PATH as `godot`).
  Anywhere: point GODOT at the binary, e.g.  GODOT=/path/to/Godot ./play.sh

Then run ./play.sh again.
MSG
	exit 1
fi

version="$("$GODOT_BIN" --version 2>/dev/null | head -n 1)"
major="${version%%.*}"
rest="${version#*.}"
minor="${rest%%.*}"
if ! [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || (( major < NEED_MAJOR || (major == NEED_MAJOR && minor < NEED_MINOR) )); then
	echo "CardClash needs Godot ${NEED_MAJOR}.${NEED_MINOR} or newer; found '${version:-unknown}' at $GODOT_BIN." >&2
	echo "Install Godot ${NEED_MAJOR}.${NEED_MINOR} (https://godotengine.org/download) or set GODOT to it." >&2
	exit 1
fi

# Import on first run, and again whenever a file in game/ changed since the last import.
stamp="game/.godot/.play_import_stamp"
if [[ ! -f "$stamp" || ! -f game/.godot/global_script_class_cache.cfg ]] \
	|| [[ -n "$(find game \( -path game/.godot -o -path game/addons \) -prune -o -newer "$stamp" -print -quit)" ]]; then
	echo "Preparing the game (importing art, fonts and scripts; the first time takes a minute)..."
	# Twice: the first pass registers scripts and imports the fonts the theme needs.
	"$GODOT_BIN" --headless --path game --import >/dev/null 2>&1 || true
	"$GODOT_BIN" --headless --path game --import >/dev/null 2>&1 || true
	if [[ ! -f game/.godot/global_script_class_cache.cfg ]]; then
		echo "The import didn't finish. Try opening game/project.godot in the Godot editor once." >&2
		exit 1
	fi
	touch "$stamp"
fi

echo "Starting CardClash with $version"
exec "$GODOT_BIN" --path game "$@"
