## NeoVim Manual

本文区分 Neovim 原生命令、LazyVim 默认键位和本仓库自定义映射。`<leader>` 在 LazyVim 中默认为空格；表格中的 `n` 为 Normal 模式。插件是否启用会影响实际按键，可通过 `:map`、`:Lazy` 和 `:LazyExtras` 检查。默认按键参见 [LazyVim Keymaps](https://www.lazyvim.org/keymaps)。

### Base

#### 光标

| Key | Description | Mode |
| --- | --- | --- |
| ctrl + o | 光标跳转(回到上一次光标所在位置) | n |
| ctrl + i | 沿跳转列表前进 | n |
| ctrl + g | 显示当前文件名和光标位置 | n |
| * | 快速搜索光标下单词（向下）| n |
| # | 快速搜索光标下单词（向上）| n |

#### Mark

| Key | Description | Mode |
| --- | --- | --- |
| `m{a-z}` / `m{A-Z}` | 设置标记：小写限当前文件，大写可跨文件 | n |
| `M{标记}` | 本仓库映射：跳到标记所在行首个非空白字符 | n |
| `dm` 后输入标记并回车 | 本仓库映射：删除指定标记 | n |

MarkDownPreView插件：可视化打开Markdown页面

原生跳转使用 `'{标记}`（按行）或反引号加标记（精确位置）；`M` 和 `dm` 是下面的自定义映射，`M` 会覆盖原来的屏幕中间行跳转。

Keymap映射：

```lua
-- Goto Mark
vim.keymap.set('n', 'M', "'")

-- Delete Mark
vim.keymap.set('n', 'dm', '<cmd>lua DelMark()<cr>', { noremap = true, silent = true })
function DelMark()
  local mark = vim.fn.input('')
  vim.cmd('delmarks ' .. mark)
end
```

#### Buffer

| Key | Description | Mode |
| --- | --- | --- |
| `<leader>bd` | 关闭buffer | n |
| `<S-h>` / `<S-l>` | 上一个 / 下一个 buffer | n |
| `<leader>bp` | 固定buffer | n |
| `<leader>bP` | 除固定的buffer全部删除 | n |
| ]e | Next Error | n |
| [e | Prev Error | n |

### Neo-tree

目录列表操作:

| Key | Description | Mode |
| --- | --- | --- |
| `<leader>e` | 打开当前文件树 | n |
| `H` | 切换过滤项可见性，是否包含 Git 忽略文件取决于 filtered_items 配置 | n |

Neo-tree 是可选插件，以上键位只在它启用时适用；`<leader>I` 不是其默认切换 Git 忽略文件按键。参见 [Neo-tree 默认配置](https://github.com/nvim-neo-tree/neo-tree.nvim/blob/main/lua/neo-tree/defaults.lua)。

### 注释

`gcc` 切换当前行注释。现代 Neovim 提供原生注释操作，旧配置也可能由插件提供，不应仅据此判断使用了 mini.comment。

### LSP

| Key | Description | Mode |
| --- | --- | --- |
| `<leader>cl` | LSPInfo | n |
| `<leader>ca` | Code Action | n |

lsp 插件:

- gopls(go LSP)
- pyright(python LSP)

> 在安装模块之后，发现依赖关系还是报错，除了直接退出重新打开nvim，还可以通过命令:LspRestart，LSP插件重新打开之后就恢复正常了。

如果需要语言增强功能，可通过开启lazyvim中的extras(:LazyExtras)中的lang模块，enable对应需要的语言模块，比如：

- lang.go
- lang.python
- lang.typescript

Mason 是工具安装管理器，`:Mason` 打开管理界面；这里不把 `lang.mason` 当作语言扩展。

### Formatting

参考链接：
> [https://www.lazyvim.org/extras/formatting/black](https://www.lazyvim.org/extras/formatting/black)

格式化 Python 代码：

1. 通过 `:LazyExtras` 启用 `formatting.black`；其配置会将 Black 加入 Mason 安装列表，并为已启用的 conform.nvim / none-ls 配置 Black。
2. 用 `:Mason` 确认 Black 已安装，使用 conform.nvim 时用 `:ConformInfo` 检查当前缓冲区的格式化器。
3. 在代码中使用 `<leader>cf` 格式化；`cf` 本身不是这个快捷键。

需要定制时，在自己的 `lua/plugins/` 下覆盖插件选项，不直接修改 `~/.local/share/nvim/lazy/conform.nvim/` 中的插件源码，否则更新会覆盖修改。插件名称是 `conform.nvim`，不是 `confirm.nvim`。参见 [Black 扩展配置](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/formatting/black.lua)。

### Treesitter

Neovim 0.10+ 可在 `lua/config/options.lua` 设置内置 Treesitter 折叠。需有对应语言的解析器和折叠查询；LazyVim 已提供的设置可优先沿用。

```lua
-- 开启代码折叠
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- 默认不折叠
vim.opt.foldlevel = 99
```

折叠操作：

| Key | Description | Mode |
| --- | --- | --- |
| zc | 折叠代码(光标下) | n |
| zo | 打开光标下折叠 | n |
| zr | 全局减少一层折叠 | n |
| zM | 折叠所有 | n |
| zR | 打开所有 | n |

旧写法 `nvim_treesitter#foldexpr()` 依赖旧版 nvim-treesitter，不是 Neovim 内置函数。参见 [Neovim Treesitter 折叠](https://neovim.io/doc/user/treesitter/#vim.treesitter.foldexpr())。

安装 Go 的 Treesitter 解析器（解析器不同于语言插件）：

```
:TSInstall go
```

`:TSInstallInfo` 是旧版 nvim-treesitter 的命令；当前分支的命令接口可能不同，查看 `:help nvim-treesitter` 和 `:checkhealth nvim-treesitter`，不要把旧命令视为各版本通用。参见 [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)。

#### 备注

问题：`Query error ... Invalid node type`。当时通过 `:TSUpdate` 更新解析器解决。若仍报错，还需检查查询文件与解析器版本是否匹配、runtimepath 是否存在重复解析器；不能保证更新一次就能修复所有同类错误。

### 项目内容搜索

| Key | Description | Mode |
| --- | --- | --- |
| `<leader>/` | 项目内容搜索（具体提供者取决于启用的 picker） | n |

`rg` 是外部搜索程序，不是 Neovim 插件；Ubuntu 安装命令：

```shell
apt-get install ripgrep
```

### Git Blame
>
> 查看代码提交历史插件

使用：

1. 找到lazy-vim的插件lua配置存放的路径：（/root/.config/nvim/lua/plugins/)
2. 新建插件lua配置文件，设置插件名称，使用快捷键等
3. 重启安装即可

```lua
return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    keys = {
      { "<leader>gb", "<cmd>BlameToggle virtual<CR>", desc = "Git blame" },
      { "<leader>gB", "<cmd>BlameToggle window<CR>", desc = "Git blame (window)" },
    },
    opts = {
      date_format = "%Y-%m-%d %H:%M",
      merge_consecutive = false,
      max_summary_width = 30,
      mappings = {
        commit_info = "K",
        stack_push = ">",
        stack_pop = "<",
        show_commit = "<CR>",
        close = { "<Esc>", "q" },
      },
    },
  },
}
```

`BlameToggle` 是插件实际注册的命令。使用 lazy.nvim 时，`opts = {}` 或显式 `config` 可以触发插件的 `setup`；不要只删除 `opts` 而省略初始化。参见 [blame.nvim](https://github.com/FabijanZulj/blame.nvim)。

### Spectre

> 批量查找替换

#### 版本与启用方式

旧版 LazyVim 曾集成 Spectre；当前默认搜索替换使用 grug-far，`<leader>sr` 不代表 Spectre。本文的 Spectre 由仓库 `plugins/spectre.lua` 单独配置。参见 [LazyVim 搜索替换配置](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/editor.lua)。

Spectre 默认使用 ripgrep 搜索，并可使用 sed 等引擎替换。

1. 打开Spectre

```vim
:Spectre
```

也可用本仓库自定义的 `<leader>gF` 打开。

1. 在Spectre UI中输入搜索关键词
2. 设置替换成的字符串
3. 在结果行使用 `<leader>rc` 替换当前行，`<leader>R` 替换全部选中结果；`dd` 切换结果是否参与替换。按键以插件当前配置为准，参见 [Spectre 映射源码](https://github.com/nvim-pack/nvim-spectre/blob/master/lua/spectre/config.lua)。

#### 额外插件

安装使用参考Git Blame插件

```lua
return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    opts = {},
    keys = {
      { '<leader>gF', '<cmd>lua require("spectre").toggle()<CR>',                        desc = "Toggle Spectre" },
      { '<leader>gf', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = "Search current word" }
    }
  }
}
```

退出窗口：

- vim命令:q;
- LazyVim 关闭窗口映射：`<leader>wd`（不是同时按下加号）

#### 备注

问题：解决查找替换后，出现Neo-tree错误( no such file or directory)
当时的规避方法：关闭 Neo-tree 文件监听，并避免在 Spectre 面板中替换打开文件。在 `lua/plugins/` 中添加以下配置；这不是所有文件不存在错误的通用修复。

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    table.insert(opts.open_files_do_not_replace_types, "spectre_panel")
    opts.filesystem.use_libuv_file_watcher = false
  end,
}
```

参考issue：
> <https://github.com/nvim-pack/nvim-spectre/issues/170>

### ColorScheme

nvim主题预览链接：
> <https://vimcolorschemes.com/top/>

修改neovim主题：

```lua
return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  }
}
```

修改neovim主题风格：

```lua
{
  "folke/tokyonight.nvim",
  lazy = true,
  opts = { style = "moon" },
}
```
