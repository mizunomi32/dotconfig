local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.font_size = 14.0
config.font = wezterm.font('HackGen Console NF')
config.use_ime = true
-- 透明度
config.window_background_opacity = 0.65
-- ブラー
config.macos_window_background_blur = 20
-- タイトルバー削除
config.window_decorations = "RESIZE"
-- ダブが１つのときタブバー非表示
config.hide_tab_bar_if_only_one_tab = true
-- タブバーも透明に
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.window_background_gradient = {
  colors = { "#000000" },
}
config.show_new_tab_button_in_tab_bar = false
config.colors = {
   tab_bar = {
     inactive_tab_edge = "none",
   },
 }


config.window_padding = {
    left = 15,
    right = 15,
    top = 15,
    bottom = 0,
  },

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
   local background = "#5c6d74"
   local foreground = "#FFFFFF"

   if tab.is_active then
     background = "#ff8c00"
     foreground = "#FFFFFF"
   end

   local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

   return {
     { Background = { Color = background } },
     { Foreground = { Color = foreground } },
     { Text = title },
   }
 end)


return config

