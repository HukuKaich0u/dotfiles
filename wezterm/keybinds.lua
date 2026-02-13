local wezterm = require("wezterm")
local act = wezterm.action

local default_opacity = 0.70
local opacity_mid = 0.90
local opacity_max = 1.00
local inactive_contrast_on = { saturation = 1.00, brightness = 0.30 }
local inactive_contrast_off = { saturation = 1.00, brightness = 1.00 }

local function toggle_window_opacity(window)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.window_background_opacity or default_opacity
  if current < 0.80 then
    overrides.window_background_opacity = opacity_mid
  elseif current < 0.95 then
    overrides.window_background_opacity = opacity_max
  else
    overrides.window_background_opacity = default_opacity
  end
  window:set_config_overrides(overrides)
end

local function toggle_inactive_pane_dim(window)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.inactive_pane_hsb or inactive_contrast_off
  if current.brightness < 0.99 then
    overrides.inactive_pane_hsb = inactive_contrast_off
  else
    overrides.inactive_pane_hsb = inactive_contrast_on
  end
  window:set_config_overrides(overrides)
end

-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window)
  local name = window:active_key_table()
  if name then
    name = "TABLE: " .. name
  end
  window:set_right_status(name or "")
end)

return {
  keys = {
    -- JISキーボード: Ctrl+@ を Escape に変換
    { key = "@", mods = "CTRL", action = act.SendKey({ key = "Escape" }) },
    {
      key = 'O',
      mods = 'CMD|SHIFT',
      action = act.ToggleAlwaysOnTop,
    },
    {
      key = "n",
      mods = "LEADER",
      action = act.SpawnWindow,
    },
    -- {
    --   -- workspaceの切り替え
    --   key = "w",
    --   mods = "LEADER",
    --   action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
    -- },
    -- {
    --   --workspaceの名前変更
    --   key = "$",
    --   mods = "LEADER",
    --   action = act.PromptInputLine({
    --     description = "(wezterm) Set workspace title:",
    --     action = wezterm.action_callback(function(win, pane, line)
    --       if line then
    --         wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
    --       end
    --     end),
    --   }),
    -- },
    -- {
    --   key = "W",
    --   mods = "LEADER|SHIFT",
    --   action = act.PromptInputLine({
    --     description = "(wezterm) Create new workspace:",
    --     action = wezterm.action_callback(function(window, pane, line)
    --       if line then
    --         window:perform_action(
    --           act.SwitchToWorkspace({
    --             name = line,
    --           }),
    --           pane
    --         )
    --       end
    --     end),
    --   }),
    -- },
    -- コマンドパレット表示
    { key = "p", mods = "SUPER", action = act.ActivateCommandPalette },
    -- Tab移動
    { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
    -- Tab入れ替え
    { key = "{", mods = "LEADER", action = act({ MoveTabRelative = -1 }) },
    { key = "}", mods = "LEADER", action = act({ MoveTabRelative = 1 }) },
    -- Tab新規作成
    { key = "t", mods = "SUPER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
    -- Tabを閉じる
    { key = "w", mods = "SUPER", action = act({ CloseCurrentTab = { confirm = true } }) },

    -- 画面フルスクリーン切り替え
    { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

    -- コピーモード
    -- { key = 'X', mods = 'LEADER', action = act.ActivateKeyTable{ name = 'copy_mode', one_shot =false }, },
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
    -- コピー
    { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
    -- 貼り付け
    { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },

    -- Pane作成 (Shift + hjkl)
    { key = "H", mods = "LEADER|SHIFT", action = act.SplitPane({ direction = "Left", size = { Percent = 50 } }) },
    { key = "J", mods = "LEADER|SHIFT", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
    { key = "K", mods = "LEADER|SHIFT", action = act.SplitPane({ direction = "Up", size = { Percent = 50 } }) },
    { key = "L", mods = "LEADER|SHIFT", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
    -- Pane移動 leader + hljk
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    -- Paneを閉じる leader + x
    { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
    -- Pane選択
    { key = "[", mods = "CTRL|SHIFT", action = act.PaneSelect },
    -- 選択中のPaneのみ表示
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    -- フォントサイズ切替
    { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
    { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
    -- フォントサイズのリセット
    { key = "0", mods = "CTRL", action = act.ResetFontSize },

    -- タブ切替 Cmd + 数字
    { key = "1", mods = "SUPER", action = act.ActivateTab(0) },
    { key = "2", mods = "SUPER", action = act.ActivateTab(1) },
    { key = "3", mods = "SUPER", action = act.ActivateTab(2) },
    { key = "4", mods = "SUPER", action = act.ActivateTab(3) },
    { key = "5", mods = "SUPER", action = act.ActivateTab(4) },
    { key = "6", mods = "SUPER", action = act.ActivateTab(5) },
    { key = "7", mods = "SUPER", action = act.ActivateTab(6) },
    { key = "8", mods = "SUPER", action = act.ActivateTab(7) },
    { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },

    -- 設定再読み込み
    { key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
    -- 非アクティブ pane のコントラスト切り替え (1.00 ⇔ 0.30)
    {
      key = "b",
      mods = "LEADER",
      action = wezterm.action_callback(function(window)
        toggle_inactive_pane_dim(window)
      end),
    },
    -- 全体透明度切り替え (0.70 -> 0.90 -> 1.00 -> 0.70)
    {
      key = "B",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function(window)
        toggle_window_opacity(window)
      end),
    },
    -- キーテーブル用
    { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
    {
      key = "a",
      mods = "LEADER",
      action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
    },
  },
  -- キーテーブル
  -- https://wezfurlong.org/wezterm/config/key-tables.html
  key_tables = {
    -- Paneサイズ調整 leader + s
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

      -- Cancel the mode by pressing escape
      { key = "Enter", action = "PopKeyTable" },
    },
    -- copyモード leader + [
    copy_mode = {
      -- 移動
      { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
      { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
      { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
      -- 最初と最後に移動
      { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
      { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
      -- 左端に移動
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
      { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
      --
      { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
      -- 単語ごと移動
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
      -- ジャンプ機能 t f
      { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
      { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
      { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
      { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
      -- 一番下へ
      { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
      -- 一番上へ
      { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
      -- viweport
      { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
      { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
      { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
      -- スクロール
      { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
      { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
      { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
      { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
      -- 範囲選択モード
      { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
      { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
      { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
      -- コピー
      { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },

      -- コピーモードを終了
      {
        key = "Enter",
        mods = "NONE",
        action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
      },
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
    },
  },
}
