#!/usr/bin/env bash
# Idempotent. Run from WSL. Re-run after every `git pull`.
set -euo pipefail
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. WezTerm config -> Windows home (WezTerm runs on the Windows side)
if command -v wslpath >/dev/null && command -v cmd.exe >/dev/null; then
  WINHOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
  cp "$DOT/.wezterm.lua" "$WINHOME/.wezterm.lua"
  echo "wezterm  -> $WINHOME/.wezterm.lua"
fi

# 2. Shell: source our snippets from ~/.bashrc (one line, added once)
LINE='[ -f ~/dotfiles/bash/init.sh ] && . ~/dotfiles/bash/init.sh'
grep -qxF "$LINE" ~/.bashrc 2>/dev/null || { printf '\n# dotfiles\n%s\n' "$LINE" >> ~/.bashrc; echo "bashrc   -> added source line"; }
echo "done. open a new shell."
