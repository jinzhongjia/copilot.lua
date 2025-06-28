-- Shared LSP command definitions
-- 共享的 LSP 命令定义

local M = {}

---@return table
function M.get_workspace_commands()
  local commands = {
    "github.copilot.generate",
    "github.copilot.status",
  }

  -- Add NES commands if enabled
  local config = require("copilot.config")
  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.enabled then
    table.insert(commands, "github.copilot.didAcceptNextEditSuggestionItem")
    table.insert(commands, "github.copilot.didRejectNextEditSuggestionItem")
  end

  return commands
end

return M
