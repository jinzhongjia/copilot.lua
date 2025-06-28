---@class NESDisplayConfig
---@field max_suggestions integer
---@field auto_show boolean
---@field ghost_text_enabled boolean

---@class NESKeymapConfig
---@field accept string
---@field reject string
---@field next string
---@field prev string
---@field toggle string
---@field jump string

---@class NESFilterConfig
---@field min_confidence number
---@field max_suggestions_per_line integer
---@field exclude_filetypes string[]

---@class NextEditSuggestionsConfig
---@field enabled boolean
---@field auto_trigger boolean
---@field debounce integer
---@field verbose_notifications boolean
---@field display NESDisplayConfig
---@field keymaps NESKeymapConfig
---@field filter NESFilterConfig

local M = {}

---@type NextEditSuggestionsConfig
M.default = {
  enabled = false,
  auto_trigger = true,
  debounce = 500,
  verbose_notifications = true,
  display = {
    max_suggestions = 3,
    auto_show = true,
    ghost_text_enabled = true,
  },
  keymaps = {
    accept = "<C-j>",
    reject = "<C-k>",
    next = "<C-l>",
    prev = "<C-h>",
    toggle = "<leader>cn",
    jump = "<C-g>",
  },
  filter = {
    min_confidence = 0.5,
    max_suggestions_per_line = 1,
    exclude_filetypes = { "help", "alpha", "dashboard", "NvimTree", "Trouble", "lspinfo" },
  },
}

---@param config NextEditSuggestionsConfig
function M.validate(config)
  vim.validate("enabled", config.enabled, "boolean")
  vim.validate("auto_trigger", config.auto_trigger, "boolean")
  vim.validate("debounce", config.debounce, "number")
  vim.validate("verbose_notifications", config.verbose_notifications, "boolean")

  vim.validate("display", config.display, "table")
  vim.validate("display.max_suggestions", config.display.max_suggestions, "number")
  vim.validate("display.auto_show", config.display.auto_show, "boolean")
  vim.validate("display.ghost_text_enabled", config.display.ghost_text_enabled, "boolean")

  vim.validate("keymaps", config.keymaps, "table")
  vim.validate("keymaps.accept", config.keymaps.accept, "string")
  vim.validate("keymaps.reject", config.keymaps.reject, "string")
  vim.validate("keymaps.next", config.keymaps.next, "string")
  vim.validate("keymaps.prev", config.keymaps.prev, "string")
  vim.validate("keymaps.toggle", config.keymaps.toggle, "string")
  vim.validate("keymaps.jump", config.keymaps.jump, "string")

  vim.validate("filter", config.filter, "table")
  vim.validate("filter.min_confidence", config.filter.min_confidence, "number")
  vim.validate("filter.max_suggestions_per_line", config.filter.max_suggestions_per_line, "number")
  vim.validate("filter.exclude_filetypes", config.filter.exclude_filetypes, "table")

  -- Ghost text is the only display method now

  -- Validate confidence range
  if config.filter.min_confidence < 0 or config.filter.min_confidence > 1 then
    error("filter.min_confidence must be between 0 and 1")
  end

  -- Validate max suggestions
  if config.display.max_suggestions < 1 then
    error("display.max_suggestions must be at least 1")
  end

  if config.filter.max_suggestions_per_line < 1 then
    error("filter.max_suggestions_per_line must be at least 1")
  end
end

return M
