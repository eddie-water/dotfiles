# dotfiles

WezTerm config + shell prompt/aliases for WSL machines.

## New machine (Windows + WSL Ubuntu)
PowerShell (admin):
```powershell
wsl --install -d Ubuntu
winget install wez.wezterm
winget install DEVCOM.JetBrainsMonoNerdFont
```
WSL:
```bash
git clone git@github.com:eddie-water/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

## Update
```bash
dotsync   # git pull + install.sh
```

## Layout
- `.wezterm.lua` — copied to `C:\Users\<you>\.wezterm.lua` by install.sh
- `bash/prompt.sh` — PS1, venv marker, WezTerm OSC 7 cwd hook
- `bash/aliases.sh` — aliases
- `bash/init.sh` — sourced from `~/.bashrc`, loads the above
