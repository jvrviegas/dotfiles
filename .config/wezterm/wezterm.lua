-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Tokyo Night'
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"
config.font_size = 12
config.enable_wayland = false

config.front_end = 'WebGpu'
config.max_fps = 120
-- config.freetype_load_flags = 'NO_HINTING'

-- Fonts
config.font = wezterm.font_with_fallback {
	{ family = 'CommitMono Nerd Font',    scale = 1 },
	{ family = 'MonoLisa Nerd Font Mono', scale = 0.95 },
	{ family = 'Agave Nerd Font',         scale = 1 },
	{ family = 'SFMono Nerd Font',        scale = 1 },
	{ family = 'MesloLGS Nerd Font',      scale = 1 },
	{ family = 'FiraCode Nerd Font',      scale = 1 },
}

-- and finally, return the configuration to wezterm
return config
