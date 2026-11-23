# no-mouse-dev
![GitHub Created At](https://img.shields.io/github/created-at/libuliduobuqiuqiu/no-mouse-dev)
![GitHub last commit](https://img.shields.io/github/last-commit/libuliduobuqiuqiu/no-mouse-dev)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/libuliduobuqiuqiu/no-mouse-dev)


## 导语
> 纯键盘开发，又叫做mouseless programing，旨在通过减少鼠标操作，完全通过用键盘进行开发工作，提高开发效率。
> 自身真实体验下来完全代替暂时还有点难度，日常公司项目开发过程，普通的IDE（goland）会使用；neovim一般都是用到自己的项目。
> 另外我只能说neovim有无限可能，而且现在有lazyvim大大降低了使用的门槛，很多插件都基本都有了，代码提示目前LSP也很完善。但是缺点也是很明显，前期你可能会需要了解到很多命令，基础的vim操作，部分会话管理和终端的操作，这些在刚上手的时候都是有一定的门槛，很容易	卡壳，所以我一般都是通过保存笔记到git上。(PS: lazyvim关于命令的导航做的很清晰，这部分前期可以参考）
> 这篇文章只是粗浅把我自己搜集的一下资料稍微整理一下，方便后期检索，有兴趣的也可以互相交流。

**个人维护的关于纯键盘开发编程笔记:**
> [https://github.com/libuliduobuqiuqiu/no-mouse-dev](https://github.com/libuliduobuqiuqiu/no-mouse-dev)

## 工具

### 一键启动多个 Markdown 文档服务

通过根目录的 `Makefile` 管理已安装的 `mdserve`，需要 Python 3.8+，支持 Linux、WSL 和 macOS，无第三方 Python 依赖。`make` 或 `make help` 查看命令帮助。

配置放在根目录 `configs/` 下：

- `md-preview.example.json`：提交到仓库的样例。
- `md-preview.json`：实际生效的本机配置，已加入 `.gitignore`。

首次运行 `make md-preview-config` 从样例创建实际配置，已有文件不会覆盖。Makefile 顶部的 `MD_PREVIEW_CONFIG` 指定实际配置，也可通过命令行覆盖。

同一配置可以定义多个服务，每个服务有独立的目录、地址和端口：

```json
{
  "default_service": "project",
  "services": {
    "project": {
      "directory": "..",
      "host": "127.0.0.1",
      "port": 8080,
      "open_browser": false,
      "default_doc": "Readme.md"
    },
    "manual": {
      "directory": "../manual",
      "host": "127.0.0.1",
      "port": 8081,
      "open_browser": false,
      "default_doc": "vim_manual.md"
    }
  }
}
```

`services` 的键是服务名称（Makefile 将 `all` 保留为批量选择值）。可继续增加任意目录，例如 `notes`、`work`。`directory` 支持 `~`、环境变量和相对于**配置文件所在目录**的路径；上例分别预览项目根目录和 `manual/`。`default_doc` 是首页文档，注意文件名大小写；`open_browser` 控制是否启动浏览器。`default_service` 保留兼容现有配置；前台和后台启动默认均选择全部服务。

```sh
make md-preview-list                    # 列出配置的服务
make md-preview-bg                      # 同时后台启动全部服务
make md-preview-bg SERVICE=manual       # 只后台启动 manual
make md-preview SERVICE=project         # 只前台启动 project，Ctrl+C 停止
make md-preview                         # 同时前台启动全部服务，Ctrl+C 一并停止
make md-preview-status                  # 查看全部服务状态
make md-preview-logs SERVICE=manual     # 只查看 manual 日志
make md-preview-stop SERVICE=manual     # 只停止 manual，其他服务继续运行
make md-preview-stop                    # 停止全部服务
```

前台启动、后台启动、停止、状态、日志命令省略 `SERVICE` 时操作全部服务，也可显式使用 `SERVICE=all`。前台模式会先启动全部选中服务，再统一等待；Ctrl+C 会停止本次启动的服务，已在运行的服务不受影响。每个服务分别保存进程状态和日志，重复启动会提示已有进程，单个服务失败时批量操作会继续处理其他服务并返回非零退出码。启动前会校验所有选中配置，同一批次配置了完全相同的监听地址时会报错。

后台启动时会输出 PID 和 `state.json` 路径。停止命令读取该记录并校验进程启动身份，先发送 `SIGTERM`，等待 5 秒仍未退出时再次校验后发送 `SIGKILL`；确认退出后删除记录。Linux 使用内核进程启动时间和系统启动标识校验，避免系统时间调整、终端宽度变化或 PID 被复用时误判。兼容旧版保存的 `ps` 记录：旧记录的时间文本变化时，仅在该 PID 的完整命令与保存值完全一致时接管，并在启停时升级记录；若身份无法匹配，会明确报错并保留记录供排查。启停命令需使用相同用户、配置文件路径及 `XDG_STATE_HOME`。

从其他目录可执行 `make -C /path/to/no-mouse-dev md-preview-bg`。切换配置可用 `make md-preview-bg MD_PREVIEW_CONFIG=/path/to/notes.json`，后续管理命令也需指定相同配置路径。服务身份由配置文件路径和服务名称共同确定；修改目录或端口后需先停止再启动，删除或重命名服务前也请先停止它。

上例访问地址分别为 `http://127.0.0.1:8080` 和 `http://127.0.0.1:8081`。mdserve 遇到端口占用会自动换端口，实际地址以前台输出或对应服务的日志为准。后台启动提示表示进程已运行，不代表 HTTP 就绪检查通过。日志为追加记录，位于 `${XDG_STATE_HOME:-~/.local/state}/md-preview/` 下各服务独立的目录。后台服务不会自动开机启动。

也可直接使用 `python3 tools/md-preview/md-preview start -b --all`，默认读取 `configs/md-preview.json`；`--service manual` 选择单个服务，`-c` 指定配置文件。

**纯键盘开发使用到的插件或者工具：**

- WSL(虚拟环境)
- WezTerm(终端工具)
- NeoVIM(IDE)
- LazyVIM(NeoVIM 配置)
- Lsp（pyright,gopls)
- zsh(oh-my-zsh配置)
- Tmux(Linux 窗口会话管理工具)
## 环境搭建
### Windows虚拟Linux系统：WSL
> 由于本身是windows系统，抛弃传统的vmware的虚拟机环境，直接使用现在微软的wsl，更加方便快捷，兼容性又好。已经基本满足我的Linux开发环境的要求，但是由于默认开启的wsl功能安装的linux系统都是会在C盘，强迫症发作一定要要安装在D盘，这部分也折腾了一下。

#### 手动安装
**手动安装指定的位置：**
> [https://www.cnblogs.com/xiaoliangyuu/p/15506352.html](https://www.cnblogs.com/xiaoliangyuu/p/15506352.html)

#### 解决异常
**启动Windows子系统报错：**
> [https://blog.csdn.net/inthat/article/details/117805383](https://blog.csdn.net/inthat/article/details/117805383)

**旧版WSL更新内核：**
> [https://learn.microsoft.com/zh-cn/windows/wsl/install-manual#step-4---download-the-linux-kernel-update-package](https://learn.microsoft.com/zh-cn/windows/wsl/install-manual#step-4---download-the-linux-kernel-update-package)

**设置默认WSL用户：(进入到解压缩的ubuntu系统目录)**
> ubuntu.exe config --default-user root

### 终端模拟器：WezTerm
> 关于终端有很多选择，自己喜欢用那个都行，这里选择wezterm主要是能通过lua脚本控制终端的设置，高度自定义，还是挺多东西可以整的。

**使用lua脚本：（wezterm.lua ）**
```lua
-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local c = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  c = wezterm.config_builder()
end


-- 配色方案（主题）
local materia = wezterm.color.get_builtin_schemes()['Brogrammer']
materia.scrollbar_thumb = '#cccccc' -- 更明显的滚动条
c.colors = materia

-- 透明背景
-- c.window_background_opacity = 0.9

-- 设置背景图片的后的字体
c.text_background_opacity  = 1

-- 设置图片
c.window_background_image = "D:\\Coding\\WezTerm\\WezTerm\\wallhaven-d66zrl.jpg"
c.window_background_image_hsb = {
  -- Darken the background image by reducing it to 1/3rd
  brightness = 0.1,

  -- You can adjust the hue by scaling its value.
  -- a multiplier of 1.0 leaves the value unchanged.
  hue = 1.0,

  -- You can adjust the saturation also.
  saturation = 1.0,
}

-- 取消 Windows 原生标题栏
c.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- 滚动条尺寸为 15 ，其他方向不需要 pad
c.window_padding = { left = 0, right = 15, top = 0, bottom = 0 }

-- 启用滚动条
c.enable_scroll_bar = true

-- 进入窗口启动命令
c.default_prog = {"wsl.exe", "--cd", "~"}

-- and finally, return the configuration to wezterm
return c
```
**终端配置详解：**
> [https://wezfurlong.org/wezterm/config/files.html](https://wezfurlong.org/wezterm/config/files.html)

**终端默认按键定义；**
> [https://wezfurlong.org/wezterm/config/default-Keyss.html](https://wezfurlong.org/wezterm/config/default-Keyss.html)

**文章：**
> [https://www.rayalto.pro/2023/10/25/wezterm-replace-windows-terminal/](https://www.rayalto.pro/2023/10/25/wezterm-replace-windows-terminal/)

### 文本编辑器：NeoVIM
入门配置：**lazyVIM**
设置自定义快捷键示例：
```lua
vim.Keyssmap.set('i', 'jj', '<esc>')
```
**LazyVim按键绑定：**
> [https://www.lazyvim.org/keymaps](https://www.lazyvim.org/keymaps)

**LazyVim Keysmaps：**
> [https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/Keysmaps.lua](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/Keysmaps.lua)

### Python LSP插件：pyright
pyright虚拟环境库设置：(pyrightconfig.json)
```json
{
  "venvPath": "/data/PythonDemo/",
  "venv": "venv"
}
```
参考官方解决方案：
> [https://microsoft.github.io/pyright/#/import-resolution?id=configuring-your-python-environment](https://microsoft.github.io/pyright/#/import-resolution?id=configuring-your-python-environment)

### Python 虚拟环境工具：Virtualenv
如何配置进入到指定项目文件夹中自动加在对应的venv目录的环境：（设置.bashrc）
```
cd() {
        builtin cd $1
        if [ -d "venv" ]; then
                source venv/bin/activate
        fi
}
```
### Unix shell：zsh && oh-my-zsh
> zsh可以理解为传统bash的扩展，能够做到很多高级功能，高级不全，主题，插件，高亮等。oh-my-zsh就是管理zsh配置的一个框架，可以通过oh-my-zsh自由安装喜欢的主题。

```bash
apt install zsh -y
```
oh-my-zsh参考链接：
> [https://ohmyz.sh/](https://ohmyz.sh/)

oh-my-zsh主题：（powerlevel10k）
> [https://github.com/romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)

### 会话管理工具：tmux
> tmux是一个会话管理工具，可以实现在一个窗口多开会话，并且能够在多个终端会话中高效切换。基本是神器，有时候可能需要在一个窗口里看到同时在打印日志，看系统负载，看请求连接数，这种只需要分割成多个会话就能做到。

```bash
apt install tmux
```
**加载标准个性化tmux配置：**
```shell
$ cd

$ git clone https://github.com/gpakosz/.tmux.git
$ ln -s -f .tmux/.tmux.conf
$ cp .tmux/.tmux.conf.local .
```
**tmux命令：**
> [https://github.com/gpakosz/.tmux](https://github.com/gpakosz/.tmux)

**参考教程：**
> [https://www.ruanyifeng.com/blog/2019/10/tmux.html](https://www.ruanyifeng.com/blog/2019/10/tmux.html)

## 备注
### 关于代理
设置ALL_PROXY,设置https_proxy,设置http_proxy（备注：自身部署服务测试接口API，有可能会走到代理访问vpn，建议下载更新软件时候才开启，默认关闭）
```
host_ip=$(cat /etc/resolv.conf | grep nameserver | cut -f 2 -d " ")
export ALL_PROXY="http://$host_ip:7890"
export https_proxy="http://$host_ip:7890"
export http_proxy="http://$host_ip:7890"
```
补充shell脚本用于快捷设置代理地址和取消代理地址,具体参考clash_for_linux.sh,增加快捷命令：
```
alias clash='source /root/clash_for_linux.sh set'
alias unclash='source /root/clash_for_linux.sh unset'
```
### 关于反人类的大写键
> 如果纯键盘开发，会发现大写键基本没什么用，但是却是占在最关键的位置，很多时候每次手指去按左ctrl的时候都会受不了，所以建议把这两个键互换，大写可以用shift按住，减少使用大写键；

**windows系统上capsLock 和 ctrl键互换：**

1. 通过win+r，regedit打开注册表；
2. 找到路径（计算机\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout）
3. 新建一个二进制值，重命名Scancode Map;
4. 编辑二进制值
```
0000 00 00 00 00 00 00 00 00
0008 03 00 00 00 1D 00 3A 00
0010 3A 00 1D 00 00 00 00 00
0018
```
### 关于最后
> 其实关于这种模式的开发，相对于传统的开发模式没有孰优孰劣之分，不要为了纯键盘而纯键盘，自己最顺手最重要，因为毕竟这些都是工具，不能真正的解决实际的业务工作。对于我来说，认为这些东西有趣，有时候折腾一下，还是蛮有成就感的就足够了，没必要完全陷入工具焦虑的误区。


