-- Hammerspoon Configuration
-- https://www.hammerspoon.org/

-- リロード設定
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

-- ウィンドウ管理のヘルパー関数
local function getFocusedWindow()
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No window focused")
    return nil
  end
  return win
end

-- ウィンドウ管理
-- 左半分
hs.hotkey.bind({"cmd", "alt"}, "Left", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

-- 右半分
hs.hotkey.bind({"cmd", "alt"}, "Right", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

-- 最大化
hs.hotkey.bind({"cmd", "alt"}, "F", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h
  win:setFrame(f)
end)

-- 上半分
hs.hotkey.bind({"cmd", "alt"}, "Up", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 下半分
hs.hotkey.bind({"cmd", "alt"}, "Down", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y + (max.h / 2)
  f.w = max.w
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 左上4分の1
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Left", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 右上4分の1
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Up", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 左下4分の1
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Down", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y + (max.h / 2)
  f.w = max.w / 2
  f.h = max.h / 2
  win:setFrame(f)
end)

-- 右下4分の1
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Right", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y + (max.h / 2)
  f.w = max.w / 2
  f.h = max.h / 2
  win:setFrame(f)
end)

-- センター配置（画面の60%）
hs.hotkey.bind({"cmd", "alt"}, "C", function()
  local win = getFocusedWindow()
  if not win then return end

  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.w = max.w * 0.6
  f.h = max.h * 0.6
  f.x = max.x + (max.w - f.w) / 2
  f.y = max.y + (max.h - f.h) / 2
  win:setFrame(f)
end)

-- 次のディスプレイへ移動
hs.hotkey.bind({"cmd", "alt"}, "N", function()
  local win = getFocusedWindow()
  if not win then return end

  win:moveToScreen(win:screen():next())
end)

-- Ctrlキーのダブルタップを検知する設定
local double_press = require("ctrlDoublePress")

-- WezTermを表示または非表示に切り替える関数（ウィンドウ番号1のみ対象、現在のディスプレイに表示）
local open_wezterm = function()
    local bundleID = "com.github.wez.wezterm" -- WezTermのBundle ID
    local app = hs.application.get(bundleID)
    local currentScreen = hs.mouse.getCurrentScreen() -- マウスがあるディスプレイを取得

    if app == nil then
        -- アプリが起動していない場合は起動
        hs.application.launchOrFocusByBundleID(bundleID)
    else
        -- 全てのウィンドウを取得してID順にソート
        local windows = app:allWindows()

        if #windows == 0 then
            -- ウィンドウがない場合は起動
            hs.application.launchOrFocusByBundleID(bundleID)
        else
            -- ID順にソートして最初のウィンドウ（ID=1）を取得
            table.sort(windows, function(a, b) return a:id() < b:id() end)
            local firstWindow = windows[1]

            if firstWindow:isMinimized() or not firstWindow:isVisible() then
                -- ウィンドウが最小化されているか非表示の場合は表示
                firstWindow:unminimize()
                -- 現在のディスプレイに移動
                firstWindow:moveToScreen(currentScreen)
                firstWindow:focus()
                app:activate()
            else
                -- ウィンドウが表示されている場合は非表示
                firstWindow:minimize()
            end
        end
    end
end

-- ダブルタップの動作を設定
double_press.timeFrame = 0.5  -- ダブルタップの間隔（秒）
double_press.action = open_wezterm


