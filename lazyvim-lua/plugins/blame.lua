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
