-- return {
--   "folke/tokyonight.nvim",
--   lazy = true,
--   opts = { style = "night" },
-- }
return {
  -- add monokai
  { "https://github.com/tanvirtin/monokai.nvim" },
  -- Configure LazyVim to load monokai_pro
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai_pro",
    },
  },
}
