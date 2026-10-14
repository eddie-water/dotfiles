export VIRTUAL_ENV_DISABLE_PROMPT=1
_venv_ps1() { [ -n "$VIRTUAL_ENV" ] && printf '(v) '; }
PROMPT_DIRTRIM=3
PS1='\[\e[32m\]$(_venv_ps1)\[\e[34m\]\w\[\e[0m\]> '

# WezTerm: report the cwd (OSC 7) before each prompt so Ctrl+click on a
# path:line reference can resolve relative paths, even while a TUI is running
if [ "$TERM_PROGRAM" = WezTerm ]; then
  _wezterm_osc7() { printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "${PWD// /%20}"; }
  PROMPT_COMMAND="_wezterm_osc7${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
