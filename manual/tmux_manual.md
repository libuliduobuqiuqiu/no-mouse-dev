# tmux 使用记录

本文同时涉及 tmux 默认绑定和 README 中安装的 [Oh my tmux 配置](https://github.com/gpakosz/.tmux)。tmux 默认前缀为 `Ctrl+b`；Oh my tmux 额外启用 `Ctrl+a`。下文 `<prefix> x` 表示先按前缀、松开，再按 `x`，不需要同时按两个前缀。

## Session

| 操作 | 命令或按键 | 来源 |
| --- | --- | --- |
| 离开会话，保留后台进程 | `<prefix> d` | tmux 默认 |
| 列出、选择会话 | `<prefix> s` | tmux 默认 |
| 连接指定会话 | 在普通 Shell 执行 `tmux attach -t <session-name>` | tmux 命令 |
| 创建新会话 | 在 Shell 执行 `tmux new-session -s <session-name>` | tmux 命令 |
| 在 tmux 中创建新会话 | `<prefix> Ctrl+c` | Oh my tmux |

在 tmux 内切换已有会话也可用 `<prefix> :` 打开命令行，输入 `switch-client -t <session-name>`。`attach` 是 tmux 命令，不是前缀后的普通按键序列。新建窗口的 `c` 不会新建会话。

## Window

| 操作 | 按键 | 来源 |
| --- | --- | --- |
| 新建窗口 | `<prefix> c` | tmux 默认 |
| 关闭当前窗口及其中的窗格 | `<prefix> &`，随后确认 | tmux 默认 |
| 选择编号对应的窗口 | `<prefix> 数字` | tmux 默认；Oh my tmux 的 `0` 选第 10 个窗口 |
| 将当前窗口移到指定编号 | `<prefix> .`，输入目标编号 | tmux 默认 `move-window` |

交换两个窗口可在 tmux 命令行执行 `swap-window -t <目标编号>`；`.` 的默认动作是移动窗口。

## Pane

| 操作 | 按键 | 来源 |
| --- | --- | --- |
| 按左、下、上、右切换窗格 | `<prefix> h/j/k/l` | Oh my tmux |
| 调整窗格边界 | `<prefix> H/J/K/L` | Oh my tmux |
| 缩放当前窗格，再按恢复 | `<prefix> z` | tmux 默认 |
| 将当前窗格拆到新窗口 | `<prefix> !` | tmux 默认 `break-pane` |
| 在专用窗口中最大化、还原当前窗格 | `<prefix> +` | Oh my tmux |

`!` 移动的是当前窗格，不是创建一个空窗口；`z` 缩放的是当前窗格，不是整个窗口。

## Copy Mode 与鼠标

- 进入复制模式：默认 `<prefix> [`，Oh my tmux 还绑定了 `<prefix> Enter`。
- 切换鼠标开关：Oh my tmux 的 `<prefix> m`。

Oh my tmux 专用按键以其 [配置源码](https://github.com/gpakosz/.tmux/blob/master/.tmux.conf) 为准。检查本机实际绑定可执行 `tmux list-keys -T prefix`。

## 状态栏与重载

下面的变量属于 Oh my tmux，应放在 `~/.tmux.conf.local`，不是 tmux 原生选项：

```sh
tmux_conf_theme_status_bg='default'
tmux_conf_theme_status_fg='white'
```

`default` 使用终端默认背景；最终是否透明取决于终端背景及状态栏各分段的配置。左右分段另有 `tmux_conf_theme_status_left_bg`、`tmux_conf_theme_status_right_bg`。

重载主配置需使用正确路径，避免依赖当前目录：

```sh
tmux source-file ~/.tmux.conf
```

原生命令语义参见 [tmux 手册](https://man.openbsd.org/tmux)。
