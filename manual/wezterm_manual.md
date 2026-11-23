# WezTerm 使用记录

## 标签页

下面是 Windows / Linux 的默认按键。切换标签页与移动标签页顺序是两种操作，`Ctrl+Shift+9` 选择最后一个标签页。

| 操作 | 默认快捷键 |
| --- | --- |
| 新建标签页 | `Ctrl+Shift+t` |
| 切换到下一个标签页 | `Ctrl+Tab` |
| 切换到上一个标签页 | `Ctrl+Shift+Tab` |
| 选择第 1–8 个标签页 | `Ctrl+Shift+1` 至 `Ctrl+Shift+8` |
| 选择最后一个标签页 | `Ctrl+Shift+9` |
| 将当前标签页向左移动 | `Ctrl+Shift+PageUp` |
| 将当前标签页向右移动 | `Ctrl+Shift+PageDown` |

参见 [WezTerm 默认按键](https://wezterm.org/config/default-keys.html)。自定义绑定会改变实际行为。

## 仓库中的背景配置

`wezterm/wezterm.lua` 先加载背景图片，再创建选择器，并将初始背景写入 `c.background`。`wezterm/backdrops/` 没有图片时使用纯色背景。

本仓库自定义的背景快捷键：Windows / Linux 使用 `Alt`，macOS 使用 `Super`。

| 操作 | Windows / Linux | macOS |
| --- | --- | --- |
| 随机背景 | `Alt+/` | `Super+/` |
| 上一张 / 下一张 | `Alt+,` / `Alt+.` | `Super+,` / `Super+.` |
| 选择背景 | `Alt+Ctrl+/` | `Super+Ctrl+/` |
| 切换专注背景 | `Alt+b` | `Super+b` |

启动 `wsl.exe` 的配置只在 Windows 生效。背景字段参见 [WezTerm background 配置](https://wezterm.org/config/lua/config/background.html)。

## Vim 与系统剪贴板

WezTerm 的 `Ctrl+Shift+c` / `Ctrl+Shift+v` 操作终端剪贴板。Vim 的 `y` 默认写入 Vim 寄存器；是否能通过 `"+y` 写入系统剪贴板，取决于 Vim / Neovim 的剪贴板支持和 provider。Neovim 可用 `:checkhealth vim.provider` 排查，不能仅靠终端复制快捷键推断 Vim 剪贴板已配置。参见 [Neovim provider 文档](https://neovim.io/doc/user/provider/)。
