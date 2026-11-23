-- Pull in the wezterm API
local wezterm = require 'wezterm'
local Config = require('utils')


-- Load images before bindings builds the background selector choices.
local backdrops = require('utils.backdrops'):set_files()
backdrops:random()
local c = Config:init():append(require('utils.bindings')).options
c.background = backdrops:initial_options()

-- 取消 Windows 原生标题栏
c.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- 滚动条尺寸为 15 ，其他方向不需要 pad
c.window_padding = { left = 0, right = 15, top = 0, bottom = 0 }

-- 启用滚动条
c.enable_scroll_bar = true

-- 进入窗口启动命令
if require("utils.platform").is_win then
   c.default_prog = {"wsl.exe", "--cd", "~"}
end

-- and finally, return the configuration to wezterm
return c
