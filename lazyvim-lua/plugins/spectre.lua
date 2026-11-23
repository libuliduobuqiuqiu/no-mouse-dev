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
