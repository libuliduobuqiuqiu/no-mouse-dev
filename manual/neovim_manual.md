## NeoVim Manual

### Base

#### 光标

| Key | Description | Mode |
| --- | --- | --- |
| ctrl + o | 光标跳转(回到上一次光标所在位置) | n |
| ctrl + i | 光标跳转（回到返回前的光标所在位置） |  |
| ctrl + g | 显示当前文件名和光标位置 | n |
| * | 快速搜索光标下单词（向下）| n |
| # | 快速搜索光标下单词（向上）| n |

#### Mark

| Key | Description | Mode |
| --- | --- | --- |
| m + <a-z>（本文件）<A-Z）（缓冲区) | Mark标记 | n |
| M + <a-z> | 跳转Mark标记 | n |
| dm + <a-z> | 取消Mark标记 | n |

MarkDownPreView插件：可视化打开Markdown页面

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
| <leader> bd | 关闭buffer | n |
| <S-hj> | 切换buffer | n |
| <leader> bp | 固定buffer | n |
| <leader> bP | 除固定的buffer全部删除 | n |
| ]e | Next Error | n |
| [e | Prev Error | n |

### Neo-tree

目录列表操作:

| Key | Description | Mode |
| --- | --- | --- |
| <S-h> | (在树形列表中）打开隐藏文件 | n |
| <leader> e | 打开当前文件树 | n |
| <leader> I | 打开显示Github Ignore文件 | n |

### Mini

注释：gcc

### LSP

| Key | Description | Mode |
| --- | --- | --- |
| <leader> cl | LSPInfo | n |
| <leader> ca | Code Action | n |

lsp 插件:

- gopls(go LSP)
- pyright(python LSP)

> 在安装模块之后，发现依赖关系还是报错，除了直接退出重新打开nvim，还可以通过命令:LspRestart，LSP插件重新打开之后就恢复正常了。

### Formatting

参考链接：
> [https://www.lazyvim.org/extras/formatting/black](https://www.lazyvim.org/extras/formatting/black)

格式化Python代码：

1. 通过:LazyExtras启用对应格式化插件formatting
2. 通过Mason下载对应Formatting配置（black）
3. 定位到confirm.nvim配置目录下，/root/.local/share/nvim/lazy/conform.nvim/lua/conform，修改配置文件
4. 在代码中使用 cf

### Treesitter

开启折叠功能(/root/.config/nvim/lua/config/lazy.lua)

```lua
-- 开启代码折叠
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
-- 默认不折叠
vim.wo.foldlevel = 99
```

折叠操作：

| Key | Description | Mode |
| --- | --- | --- |
| zc | 折叠代码(光标下) | n |
| zr | 打开代码(光标下) | n |
| zM | 折叠所有 | n |
| zR | 打开所有 | n |

需要安装支持额外语言(go)的插件：

```
TSInstall go
```

查看已安装支持的语言

```
TSInstallInfo
```

#### 备注

问题： linux64/share/nvim/runtime/lua/vim/treesitter/query.lua:251: Query error at 9:4. Invalid node type "<":
解决方法：```:TSUpdate```

### Telescope

| Key | Description | Mode |
| --- | --- | --- |
| <leader> / | 全文搜索 | n |

Ubuntu需要安装额外插件：

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
    cmd = "ToggleBlame",
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

> opts可不填，但是不存在可能不生效

### Spectre

> 批量查找替换

#### lazyVim默认集成

> Telescope + Spectre, Spectre默认使用ripgrep

1. 打开Spectre

```vim
<leader> sr
```

2. 在Spectre UI中输入搜索关键词
3. 设置替换成的字符串
4. 选择需要替换的文件或者目录: \r替换单个,\s替换全部

#### 额外插件

安装使用参考Git Blame插件

```lua
return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    keys = {
      { '<leader>gF', '<cmd>lua require("spectre").toggle()<CR>',                        desc = "Toggle Spectre" },
      { '<leader>gf', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = "Search current word" }
    }
  }
}
return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "ToggleBlame",
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

退出窗口：

- vim命令:q;
- neovim命令：<leader>w+d

#### 备注

问题：解决查找替换后，出现Neo-tree错误( no such file or directory)
解决方法：关闭neo-tree部分配置项，在nvim中plugins目录新建lua配置

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
