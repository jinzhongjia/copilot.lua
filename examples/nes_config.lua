-- Example configuration for Next Edit Suggestions (NES) integration
-- 示例：Next Edit Suggestions (NES) 集成配置

-- Basic configuration with NES enabled
-- 基本配置，启用 NES 功能
require("copilot").setup({
  suggestion = {
    enabled = true,
    auto_trigger = false,
    debounce = 75,
    keymap = {
      accept = "<M-l>",
      accept_word = false,
      accept_line = false,
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
  panel = {
    enabled = true,
    auto_refresh = false,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>",
    },
    layout = {
      position = "bottom",
      ratio = 0.4,
    },
  },
  -- Next Edit Suggestions configuration
  -- Next Edit Suggestions 配置
  next_edit_suggestions = {
    enabled = true,
    auto_trigger = true,
    debounce = 500,
    display = {
      type = "float",
      max_suggestions = 3,
      auto_show = true,
      timeout = 5000,
    },
    keymaps = {
      accept = "<C-y>",
      reject = "<C-n>",
      next = "<C-]>",
      prev = "<C-[>",
      toggle = "<leader>cn",
    },
    filter = {
      min_confidence = 0.5,
      max_suggestions_per_line = 1,
      exclude_filetypes = { "help", "alpha", "dashboard", "NvimTree", "Trouble", "lspinfo" },
    },
  },
  filetypes = {
    yaml = false,
    markdown = false,
    help = false,
    gitcommit = false,
    gitrebase = false,
    hgcommit = false,
    svn = false,
    cvs = false,
    ["."] = false,
  },
  copilot_node_command = "node", -- Node.js version must be > 18.x
  server_opts_overrides = {},
})

-- Advanced configuration example
-- 高级配置示例
--[[
require("copilot").setup({
  next_edit_suggestions = {
    enabled = true,
    auto_trigger = true,
    debounce = 300, -- Faster response
    display = {
      type = "both", -- Show both float window and inline highlights
      max_suggestions = 5,
      auto_show = true,
      timeout = 8000, -- Longer timeout
    },
    keymaps = {
      accept = "<Tab>", -- Use Tab to accept
      reject = "<S-Tab>", -- Use Shift+Tab to reject
      next = "<C-j>", -- Use Ctrl+j for next
      prev = "<C-k>", -- Use Ctrl+k for previous
      toggle = "<leader>ct", -- Custom toggle key
    },
    filter = {
      min_confidence = 0.7, -- Higher confidence threshold
      max_suggestions_per_line = 2,
      exclude_filetypes = { 
        "help", "alpha", "dashboard", "NvimTree", 
        "Trouble", "lspinfo", "mason", "lazy",
        "TelescopePrompt", "TelescopeResults"
      },
    },
  },
})
--]]

-- You can also setup custom autocmds for NES
-- 您还可以为 NES 设置自定义自动命令
vim.api.nvim_create_autocmd("User", {
  pattern = "CopilotNESEnabled",
  callback = function()
    vim.notify("Next Edit Suggestions enabled!", vim.log.levels.INFO)
  end,
})

-- Custom command to toggle NES
-- 自定义命令来切换 NES
vim.api.nvim_create_user_command("CopilotNESToggle", function()
  require("copilot.nes").toggle_nes()
end, {})

-- Show NES status in statusline (requires a statusline plugin)
-- 在状态栏显示 NES 状态（需要状态栏插件）
--[[
local function copilot_nes_status()
  local nes = require("copilot.nes")
  if nes and nes.contexts then
    local current_buf = vim.api.nvim_get_current_buf()
    local ctx = nes.contexts[current_buf]
    if ctx and ctx.suggestions and #ctx.suggestions > 0 then
      return string.format("NES(%d)", #ctx.suggestions)
    end
  end
  return ""
end
--]]
