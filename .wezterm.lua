local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Lausse Palette (source of truth: dsplot/palettes/lausse.py)
local INK, SLATE, BONE, CREAM = '#0B080F', '#272C34', '#CEC5AC', '#FDFDEA'
local MAROON, RED, SCARLET, OCHRE = '#5F100E', '#A7221F', '#CB2B26', '#C5904C'
local SKY, CERULEAN, PERIWINKLE, COBALT, MIDNIGHT = '#79ACE8', '#30A0DA', '#4769DF', '#104DB2', '#123561'
-- Not in the palette: ash is slate+bone, and the covers have no green or magenta
local ASH = '#7A7870'

-- Four schemes from the one palette. Each pair shares its chrome (cursor,
-- selection, tab bar); the HC variant swaps in the ansi/brights rows below.
-- Contrast ratios are against the scheme's own background (WCAG):
--   normal    >= 6.5:1    HC normal  >= 7:1
--   bright    >= 5:1      HC bright  >= 5.5:1 on cream, >= 9:1 on ink
local function dark_scheme(ansi, brights, bright_black, background)
  return {
    background = background or INK,
    foreground = CREAM,
    cursor_bg = SCARLET,
    cursor_border = SCARLET,
    cursor_fg = INK,
    selection_bg = MIDNIGHT,
    selection_fg = CREAM,
    split = MAROON,
    scrollbar_thumb = SLATE,
    compose_cursor = OCHRE,
    ansi = ansi,
    brights = brights,
    tab_bar = {
      background = background or INK,
      active_tab = { bg_color = SCARLET, fg_color = CREAM },
      inactive_tab = { bg_color = background or INK, fg_color = bright_black },
      inactive_tab_hover = { bg_color = SLATE, fg_color = CREAM },
      new_tab = { bg_color = background or INK, fg_color = bright_black },
      new_tab_hover = { bg_color = SLATE, fg_color = CREAM },
    },
  }
end

local function light_scheme(ansi, brights)
  return {
    background = CREAM,
    foreground = INK,
    cursor_bg = SCARLET,
    cursor_border = SCARLET,
    cursor_fg = CREAM,
    selection_bg = BONE,
    selection_fg = INK,
    split = INK,
    scrollbar_thumb = BONE,
    compose_cursor = OCHRE,
    ansi = ansi,
    brights = brights,
    tab_bar = {
      background = BONE,
      active_tab = { bg_color = SCARLET, fg_color = CREAM },
      inactive_tab = { bg_color = BONE, fg_color = SLATE },
      inactive_tab_hover = { bg_color = CREAM, fg_color = INK },
      new_tab = { bg_color = BONE, fg_color = SLATE },
      new_tab_hover = { bg_color = CREAM, fg_color = INK },
    },
  }
end

-- Alternate dark papers: the same ansi rows as Lausse Dark on a lifted, slightly
-- violet black and on midnight pulled down to a deep indigo
local SOFT_BLACK, INDIGO = '#18151E', '#0E1628'

--                             black  red        green      yellow     blue        magenta    cyan       white
local DARK_ANSI    = { SLATE,     SCARLET,   '#8FA865', OCHRE,     PERIWINKLE, '#B06AA8', CERULEAN,  BONE }
local DARK_BRIGHTS = { ASH,       '#E5584F', '#AFC98A', '#DDB077', '#7B93EC',  '#C98BC2', SKY,       CREAM }

config.color_schemes = {
  ['Lausse Dark'] = dark_scheme(DARK_ANSI, DARK_BRIGHTS, ASH),
  ['Lausse Soft Black'] = dark_scheme(DARK_ANSI, DARK_BRIGHTS, ASH, SOFT_BLACK),
  ['Lausse Indigo'] = dark_scheme(DARK_ANSI, DARK_BRIGHTS, ASH, INDIGO),
  -- Scarlet, periwinkle and magenta sit under 5:1 on ink, so HC lifts them to
  -- 7:1 (they go salmon / cornflower / orchid); bright black becomes bone-gray
  ['Lausse Dark HC'] = dark_scheme(
    { SLATE,     '#E67C79', '#8FA865', OCHRE,     '#7F97E9',  '#C088BA', '#36A3DB', BONE },
    { '#9D9B92', '#EF9792', '#AFC98A', '#DDB077', '#9AADF0',  '#D29ECC', '#84B3EA', CREAM },
    '#9D9B92'),
  -- On paper the brights can't be lighter or they wash out, so each is the
  -- palette hue darkened until it reads
  ['Lausse Light'] = light_scheme(
    { INK,       RED,       '#4D632D', '#785427', COBALT,     '#7A3B74', '#186187', BONE },
    { ASH,       SCARLET,   '#5B7535', '#8F642E', '#365BDC',  '#894A82', '#1D74A1', CREAM }),
  -- Same hues, each nudged darker until it clears 7:1 / 5.5:1; bright black is slate
  ['Lausse Light HC'] = light_scheme(
    { INK,       RED,       '#485C2A', '#725025', COBALT,     '#7A3B74', '#175C81', BONE },
    { SLATE,     '#C22924', '#566E32', '#875F2C', '#365BDC',  '#894A82', '#1B6C96', CREAM }),
}

-- Moods: one row per scheme in config.color_schemes. opacity is how much of the
-- palette's background tints the glass (lower = more see-through). The light
-- papers stay solid: whatever shows through them turns cream gray.
local MOODS = {
  ['Lausse Dark'] = { opacity = 0.55, inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 } },
  ['Lausse Dark HC'] = { opacity = 0.85, inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 } },
  ['Lausse Soft Black'] = { opacity = 0.55, inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 } },
  ['Lausse Indigo'] = { opacity = 0.55, inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 } },
  ['Lausse Light'] = { opacity = 1.0, inactive_pane_hsb = { saturation = 0.9, brightness = 0.93 } },
  ['Lausse Light HC'] = { opacity = 1.0, inactive_pane_hsb = { saturation = 0.9, brightness = 0.95 } },
}

-- Time of day: each mood starts at its hour and runs until the next row
local SCHEDULE = {
  { from = 7, mood = 'Lausse Light' },
  { from = 19, mood = 'Lausse Dark' },
}

local function mood_for_now()
  local hour = tonumber(os.date '%H')
  local name = SCHEDULE[#SCHEDULE].mood -- before the first row it is still last night's
  for _, slot in ipairs(SCHEDULE) do
    if hour >= slot.from then
      name = slot.mood
    end
  end
  return name
end

-- Works on the config itself and on a window's overrides
local function apply_mood(target, name)
  target.color_scheme = name
  target.window_background_opacity = MOODS[name].opacity
  target.inactive_pane_hsb = MOODS[name].inactive_pane_hsb
end

local loaded_mood = mood_for_now()
local mood_reload_at = 0 -- when the clock last asked for a mood reload

-- Look
apply_mood(config, loaded_mood)
config.win32_system_backdrop = 'Acrylic'      -- blur what is behind the window
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 11
-- Pane dividers are drawn at underline thickness, so this fattens them (and
-- underlines and box-drawing lines with them)
config.underline_thickness = '3px'
config.window_decorations = 'RESIZE'          -- no title bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_padding = { left = 16, right = 16, top = 12, bottom = 10 }
config.default_cursor_style = 'SteadyBlock'
config.scrollback_lines = 10000

-- Open straight into WSL (check names with: wsl -l -v)
local wsl_domains = wezterm.default_wsl_domains()
for _, domain in ipairs(wsl_domains) do
  domain.default_cwd = '~' -- Linux home, not C:\Users\<you>
end
config.wsl_domains = wsl_domains
config.default_domain = 'WSL:Ubuntu'
-- Any domain with no shell of its own (the persistent 'unix' mux) also opens Ubuntu
config.default_prog = { 'wsl.exe', '-d', 'Ubuntu', '--cd', '~' }

-- Persistent sessions: detach/reattach like tmux
config.unix_domains = { { name = 'unix' } }

-- Crosshair: in a 2x2 tab the two center lines move as one cross. Splits nest
-- in twos, so one center line is really two halves (one per column, or one
-- per row) that move on their own. Move either half, by mouse or with
-- Alt+Shift+H/J/K/L, and the other follows. The exact center still catches
-- only the full-length line, so a diagonal move is two drags. Lua can't see
-- the mouse or resize a split directly, so this polls the layout and moves
-- the half left behind with AdjustPaneSize. That only acts on the focused
-- pane, so focus hops to that half and straight back (programs that track
-- focus, like vim, see a blip). A 2x2 that is already uneven is left alone
-- until you move one of its halves. Local and WSL tabs only: in an attached
-- mux ('unix') each focus change round-trips through the server, and a quick
-- hop and back can echo there forever.
config.status_update_interval = 100 -- poll rate in ms (also drives update-right-status below)

local crosshair = {} -- tab id -> where each center line's halves were last seen
local crosshair_busy = false -- the poll and the resize keys must not interleave

-- The tab as a 2x2 grid, or nil. Each center line has two halves; a half's
-- `at` is the cell column/row its divider sits on, and its `quads` are the two
-- panes it separates (either one steers that half with AdjustPaneSize).
local function center_lines(tab)
  local info = tab:panes_with_info()
  if #info ~= 4 then
    return nil
  end
  local q = {}
  for _, p in ipairs(info) do
    local corner = (p.top == 0 and 't' or 'b') .. (p.left == 0 and 'l' or 'r')
    if p.is_zoomed or q[corner] then
      return nil
    end
    q[corner] = p
  end
  local tl, tr, bl, br = q.tl, q.tr, q.bl, q.br
  -- every quad meets its neighbours across a one-cell divider
  if tl.left + tl.width + 1 ~= tr.left or bl.left + bl.width + 1 ~= br.left
      or tl.top + tl.height + 1 ~= bl.top or tr.top + tr.height + 1 ~= br.top then
    return nil
  end
  return {
    col = { { at = tr.left - 1, quads = { tl, tr } }, { at = br.left - 1, quads = { bl, br } } },
    row = { { at = bl.top - 1, quads = { tl, bl } }, { at = br.top - 1, quads = { tr, br } } },
    home = tl.is_active and tl or tr.is_active and tr or bl.is_active and bl or br,
  }
end

-- Also notes the tab size: resizing the window shifts both halves itself
-- (unevenly once a quad is down to one row), which is not a user move
local function line_spots(tab, lines)
  local size = tab:get_size()
  return {
    col = { lines.col[1].at, lines.col[2].at },
    row = { lines.row[1].at, lines.row[2].at },
    size = size.cols .. 'x' .. size.rows,
  }
end

local STEER = { col = { 'Left', 'Right' }, row = { 'Up', 'Down' } }

-- Slide one half of a center line to `to`, focusing its side first if needed
local function move_half(window, axis, half, to, home)
  local hop = not (half.quads[1].is_active or half.quads[2].is_active)
  local steer = half.quads[1]
  if hop then
    window:perform_action(act.ActivatePaneByIndex(steer.index), steer.pane)
  end
  local by = to - half.at
  window:perform_action(act.AdjustPaneSize { STEER[axis][by < 0 and 1 or 2], math.abs(by) }, steer.pane)
  if hop then
    window:perform_action(act.ActivatePaneByIndex(home.index), home.pane)
  end
end

local function sync_center_lines(window)
  local tab = window:active_tab()
  if not tab then
    return
  end
  local id = tab:tab_id()
  local lines = center_lines(tab)
  local domain = lines and lines.home.pane:get_domain_name()
  if not lines or not (domain == 'local' or domain:sub(1, 4) == 'WSL:') then
    crosshair[id] = nil
    return
  end
  -- copy mode, the launcher and other overlays block pane moves; wait them out
  if window:active_pane():pane_id() ~= tab:active_pane():pane_id() then
    return
  end
  local seen = crosshair[id]
  crosshair[id] = line_spots(tab, lines)
  if not seen or seen.size ~= crosshair[id].size then
    return
  end
  for _, axis in ipairs { 'col', 'row' } do
    local a, b = lines[axis][1], lines[axis][2]
    local last = seen[axis]
    -- the half that moved since the last look leads; the one left behind follows
    local lead, follow
    if a.at ~= b.at then
      if a.at ~= last[1] and b.at == last[2] then
        lead, follow = a, b
      elseif b.at ~= last[2] and a.at == last[1] then
        lead, follow = b, a
      end
    end
    if follow then
      move_half(window, axis, follow, lead.at, lines.home)
      -- remember where things really landed (a move can fall short)
      local now = center_lines(tab)
      crosshair[id] = now and line_spots(tab, now) or nil
      return
    end
  end
end

local function link_center_lines(window)
  if crosshair_busy then
    return
  end
  crosshair_busy = true
  local ok, err = pcall(sync_center_lines, window)
  crosshair_busy = false
  if not ok then
    wezterm.log_error('crosshair: ' .. tostring(err))
  end
end

wezterm.on('update-status', link_center_lines)

-- Alt+Shift+H/J/K/L: resize, then pull the other half of the line along now
-- rather than on the next poll
local function resize(direction)
  return wezterm.action_callback(function(window, pane)
    window:perform_action(act.AdjustPaneSize { direction, 5 }, pane)
    link_center_lines(window)
  end)
end

-- Keys: no leader. Alt = panes and tabs, Alt+Shift = resize and the rarer
-- session things, Ctrl+Shift = browser-style (new tab/window, copy/paste).
-- New panes/tabs/windows start in ~. Without an explicit cwd they inherit the
-- current pane's, which wezterm can only see as wsl.exe's Windows cwd.
local IN_HOME = { domain = 'CurrentPaneDomain', cwd = '~' }
config.keys = {
  -- splits
  { key = '\\', mods = 'ALT', action = act.SplitHorizontal(IN_HOME) },
  { key = '-',  mods = 'ALT', action = act.SplitVertical(IN_HOME) },
  -- move between panes (vim keys)
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  -- resize panes (a 2x2 moves as a crosshair, see above)
  { key = 'H', mods = 'ALT|SHIFT', action = resize 'Left' },
  { key = 'J', mods = 'ALT|SHIFT', action = resize 'Down' },
  { key = 'K', mods = 'ALT|SHIFT', action = resize 'Up' },
  { key = 'L', mods = 'ALT|SHIFT', action = resize 'Right' },
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },
  -- tabs
  { key = 'T', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab(IN_HOME) },
  { key = 'N', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewWindow(IN_HOME) },
  { key = ']', mods = 'ALT', action = act.ActivateTabRelative(1) },
  { key = '[', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  -- workspaces (named sessions) + fuzzy switcher
  { key = 'S', mods = 'ALT|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 'N', mods = 'ALT|SHIFT', action = act.PromptInputLine {
      description = 'New workspace name:',
      action = wezterm.action_callback(function(win, pane, line)
        if line and line ~= '' then
          win:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
  } },
  -- attach/detach the persistent mux
  { key = 'A', mods = 'ALT|SHIFT', action = act.AttachDomain 'unix' },
  { key = 'D', mods = 'ALT|SHIFT', action = act.DetachDomain { DomainName = 'unix' } },
  -- copy mode (vim-style scrollback selection)
  { key = 'C', mods = 'ALT|SHIFT', action = act.ActivateCopyMode },
  -- Shift+Enter = newline in TUIs like claude. A terminal sends the same byte
  -- for Enter and Shift+Enter, so send ESC CR instead, which claude reads as
  -- "insert newline" (same thing its /terminal-setup configures elsewhere)
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b\r' },
  -- scroll one line at a time
  { key = 'UpArrow',   mods = 'CTRL|SHIFT', action = act.ScrollByLine(-1) },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ScrollByLine(1) },
  -- pin this window to a mood, or hand it back to the clock
  { key = 'M', mods = 'ALT|SHIFT', action = wezterm.action_callback(function(window, pane)
      local choices = { { label = 'Auto (follow the clock)', id = 'auto' } }
      for name in pairs(MOODS) do
        table.insert(choices, { label = name, id = name })
      end
      table.sort(choices, function(x, y) return x.label < y.label end)
      window:perform_action(act.InputSelector {
        title = 'Mood',
        choices = choices,
        action = wezterm.action_callback(function(win, _, id)
          if not id then
            return
          end
          local overrides = win:get_config_overrides() or {}
          if id == 'auto' then
            overrides.color_scheme, overrides.window_background_opacity, overrides.inactive_pane_hsb = nil, nil, nil
          else
            apply_mood(overrides, id)
          end
          win:set_config_overrides(overrides)
        end),
      }, pane)
    end) },
}

-- Alt+1..9 jumps to that tab
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1) })
end

-- The tab bar's + button also opens in ~ (right-click still shows the launcher)
wezterm.on('new-tab-button-click', function(window, pane, button)
  if button == 'Left' then
    window:perform_action(act.SpawnCommandInNewTab(IN_HOME), pane)
    return false
  end
end)

-- Show the current workspace in the status bar
wezterm.on('update-right-status', function(window)
  window:set_right_status(' ' .. window:active_workspace() .. ' ')
  -- This fires every status_update_interval, so it doubles as the clock for SCHEDULE.
  -- A good reload starts fresh; if this file is broken at the hour, retry once a
  -- minute rather than every tick (saving the fix reloads right away anyway).
  if mood_for_now() ~= loaded_mood and os.time() - mood_reload_at >= 60 then
    mood_reload_at = os.time()
    wezterm.reload_configuration()
  end
end)

-- Links: Ctrl+click opens URLs. WezTerm's only default link binding is a plain
-- click, so Ctrl has to be bound here. Inside a TUI that reports the mouse
-- (Claude Code, vim) hold Shift as well: Shift bypasses mouse reporting and is
-- stripped before matching, so Ctrl+Shift+click lands on the Ctrl binding.
-- The Down binding is a no-op so Ctrl+click does not also start a selection.
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.OpenLinkAtMouseCursor },
  { event = { Down = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.Nop },
}
-- This also makes path:line references like scripts/foo.py:42 clickable (Claude
-- Code prints these as plain text, so the regex is what makes them links).
-- Ctrl+click opens them in VS Code.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[([\w./~-]+\.\w+):(\d+)\b]],
  format = 'file://$1:$2',
})

-- Ctrl+click opens the link under the pointer, also when a program (vim with
-- mouse on, etc.) has mouse reporting enabled. The Nop stops the press from
-- starting a text selection.
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.OpenLinkAtMouseCursor },
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', mouse_reporting = true, action = act.OpenLinkAtMouseCursor },
  { event = { Down = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.Nop },
  { event = { Down = { streak = 1, button = 'Left' } }, mods = 'CTRL', mouse_reporting = true, action = act.Nop },
}

-- Launch VS Code from wezterm rather than typing into the pane: inside a TUI
-- (claude, vim, ...) typed text goes to the program, not to a shell. Relative
-- paths resolve against the pane's cwd, which the shell reports via OSC 7
-- (see the WezTerm block in ~/.bashrc); with no report they resolve against ~.
wezterm.on('open-uri', function(window, pane, uri)
  wezterm.log_info('open-uri: ' .. uri)
  local path, line = uri:match '^file://(.+):(%d+)$'
  if not path then
    return
  end
  local cwd = pane:get_current_working_dir()
  local dir = cwd and cwd.file_path or '~'
  -- --exec runs sh directly (the `--` form, which goes through the login
  -- shell, did nothing when launched from wezterm). To debug, swap /dev/null
  -- for a log file and check Ctrl+Shift+L for the open-uri line.
  local cmd = 'code -g ' .. path .. ':' .. line .. ' >/dev/null 2>&1'
  wezterm.log_info('open-uri: cwd=' .. dir .. ' cmd=' .. cmd)
  wezterm.background_child_process {
    'wsl.exe', '-d', 'Ubuntu', '--cd', dir, '--exec', 'sh', '-c', cmd,
  }
  return false
end)

return config
