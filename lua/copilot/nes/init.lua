local logger = require("copilot.logger")
local config = require("copilot.config")
local api = require("copilot.api")
local c = require("copilot.client")

local M = {}

---@alias copilot_nes_suggestion { id: string, type: string, range: table, newText: string, description?: string, confidence?: number, created_at: number, status: string }
---@alias copilot_nes_context { suggestions: copilot_nes_suggestion[], current_suggestion: integer|nil, client_id: integer|nil, buffer_id: integer|nil, last_change_time: number, debounce_timer: any|nil, config: table }

local nes = {
  setup_done = false,
  augroup = "copilot.nes",
  ns_id = vim.api.nvim_create_namespace("copilot.nes"),
  contexts = {},
}

-- Expose namespace for other modules
M.ns_id = nes.ns_id

---@param bufnr? integer
---@return copilot_nes_context
local function get_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = nes.contexts[bufnr]
  logger.trace("NES get context", ctx)
  if not ctx then
    ctx = {
      suggestions = {},
      current_suggestion = nil,
      client_id = nil,
      buffer_id = bufnr,
      last_change_time = 0,
      debounce_timer = nil,
      config = config.next_edit_suggestions or {},
    }
    nes.contexts[bufnr] = ctx
    logger.trace("NES new context", ctx)
  end
  return ctx
end

---@param ctx copilot_nes_context
local function reset_context(ctx)
  logger.trace("NES reset context", ctx)
  ctx.suggestions = {}
  ctx.current_suggestion = nil
  ctx.last_change_time = 0
  if ctx.debounce_timer then
    vim.fn.timer_stop(ctx.debounce_timer)
    ctx.debounce_timer = nil
  end
end

---@param bufnr? integer
local function clear_suggestions(bufnr)
  local ctx = get_context(bufnr)
  reset_context(ctx)
  require("copilot.nes.display").clear_display(bufnr, nes.ns_id)
end

---@param result table LSP result from publishNextEditSuggestions
---@param client_id integer
---@param bufnr integer
function M.handle_suggestions(result, client_id, bufnr)
  logger.trace("NES handle suggestions", result)

  local ctx = get_context(bufnr)
  ctx.client_id = client_id

  if not result or not result.suggestions then
    logger.trace("NES no suggestions received")
    clear_suggestions(bufnr)
    return
  end

  -- Process and store suggestions
  ctx.suggestions = {}
  for i, suggestion in ipairs(result.suggestions) do
    local nes_suggestion = {
      id = suggestion.id or ("nes_" .. i),
      type = "next_edit_suggestion",
      range = suggestion.range,
      newText = suggestion.newText or suggestion.text,
      description = suggestion.description,
      confidence = suggestion.confidence or 0.8,
      created_at = os.time(),
      status = "pending",
    }
    table.insert(ctx.suggestions, nes_suggestion)
  end

  if #ctx.suggestions > 0 then
    ctx.current_suggestion = 1
    require("copilot.nes.display").show_suggestions(ctx, bufnr, nes.ns_id)
    logger.trace(string.format("NES: Showing %d suggestions for buffer %d", #ctx.suggestions, bufnr))
  end
end

---@param result table
---@param client_id integer
function M.handle_accept_response(result, client_id)
  logger.trace("NES handle accept response", result)
  -- Handle response from accept command
end

---@param result table
---@param client_id integer
function M.handle_reject_response(result, client_id)
  logger.trace("NES handle reject response", result)
  -- Handle response from reject command
end

---@param bufnr? integer
function M.request_suggestions(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = get_context(bufnr)

  -- Debounce mechanism
  if ctx.debounce_timer then
    vim.fn.timer_stop(ctx.debounce_timer)
  end

  ctx.debounce_timer = vim.fn.timer_start(ctx.config.debounce or 500, function()
    ctx.debounce_timer = nil
    -- Mark that we're ready to receive NES suggestions
    -- The LSP server will send publishNextEditSuggestions based on document changes
    logger.trace("NES ready to receive suggestions for buffer", bufnr)
  end)
end

---@param bufnr? integer
function M.accept_current_suggestion(bufnr)
  local ctx = get_context(bufnr)
  if not ctx.current_suggestion or #ctx.suggestions == 0 then
    logger.trace("NES accept: no current suggestion")
    return
  end

  local suggestion = ctx.suggestions[ctx.current_suggestion]
  suggestion.status = "accepted"

  local client = c.get()
  if client then
    -- Send accept command to LSP server
    api.nes_accept_suggestion(client, { id = suggestion.id }, function(err, result)
      M.handle_accept_response(result, client.id)
    end)

    -- Apply the edit and jump to suggestion location
    local range = suggestion.range
    local newText = suggestion.newText
    local target_bufnr = bufnr or vim.api.nvim_get_current_buf()

    vim.schedule(function()
      -- Jump to suggestion location first
      if range and range.start then
        local line = range.start.line + 1 -- Convert to 1-based
        local col = range.start.character
        vim.api.nvim_win_set_cursor(0, { line, col })
      end
      
      -- Apply the text edit
      vim.lsp.util.apply_text_edits(
        { { range = range, newText = newText } },
        target_bufnr,
        "utf-8"
      )
    end)
  end

  clear_suggestions(bufnr)

  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.verbose_notifications then
    vim.notify("NES: Suggestion accepted", vim.log.levels.INFO)
  end
end

---@param bufnr? integer
function M.reject_current_suggestion(bufnr)
  local ctx = get_context(bufnr)
  if not ctx.current_suggestion or #ctx.suggestions == 0 then
    logger.trace("NES reject: no current suggestion")
    return
  end

  local suggestion = ctx.suggestions[ctx.current_suggestion]
  suggestion.status = "rejected"

  local client = c.get()
  if client then
    -- Send reject command to LSP server
    api.nes_reject_suggestion(client, { id = suggestion.id }, function(err, result)
      M.handle_reject_response(result, client.id)
    end)
  end

  -- Remove current suggestion and show next
  table.remove(ctx.suggestions, ctx.current_suggestion)

  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.verbose_notifications then
    vim.notify("NES: Suggestion rejected", vim.log.levels.INFO)
  end

  if #ctx.suggestions == 0 then
    clear_suggestions(bufnr)
    if nes_config and nes_config.verbose_notifications then
      vim.notify("NES: No more suggestions", vim.log.levels.INFO)
    end
  elseif ctx.current_suggestion > #ctx.suggestions then
    ctx.current_suggestion = 1
    require("copilot.nes.display").show_suggestions(ctx, bufnr, nes.ns_id)
  else
    require("copilot.nes.display").show_suggestions(ctx, bufnr, nes.ns_id)
  end
end

---@param bufnr? integer
function M.next_suggestion(bufnr)
  local ctx = get_context(bufnr)
  if #ctx.suggestions <= 1 then
    return
  end

  ctx.current_suggestion = (ctx.current_suggestion % #ctx.suggestions) + 1
  require("copilot.nes.display").show_suggestions(ctx, bufnr, nes.ns_id)

  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.verbose_notifications then
    vim.notify(string.format("NES: Suggestion %d/%d", ctx.current_suggestion, #ctx.suggestions), vim.log.levels.INFO)
  end
end

---@param bufnr? integer
function M.prev_suggestion(bufnr)
  local ctx = get_context(bufnr)
  if #ctx.suggestions <= 1 then
    return
  end

  ctx.current_suggestion = ctx.current_suggestion - 1
  if ctx.current_suggestion < 1 then
    ctx.current_suggestion = #ctx.suggestions
  end
  require("copilot.nes.display").show_suggestions(ctx, bufnr, nes.ns_id)

  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.verbose_notifications then
    vim.notify(string.format("NES: Suggestion %d/%d", ctx.current_suggestion, #ctx.suggestions), vim.log.levels.INFO)
  end
end

---@param bufnr? integer
function M.jump_to_current_suggestion(bufnr)
  local ctx = get_context(bufnr)
  if not ctx.current_suggestion or #ctx.suggestions == 0 then
    logger.trace("NES jump: no current suggestion")
    return
  end

  local suggestion = ctx.suggestions[ctx.current_suggestion]
  local range = suggestion.range
  
  if range and range.start then
    local line = range.start.line + 1 -- Convert to 1-based
    local col = range.start.character
    vim.api.nvim_win_set_cursor(0, { line, col })
    
    local nes_config = config.next_edit_suggestions
    if nes_config and nes_config.verbose_notifications then
      vim.notify(string.format("NES: Jumped to suggestion at line %d", line), vim.log.levels.INFO)
    end
  end
end

---@param bufnr? integer
function M.get_status(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local nes_config = config.next_edit_suggestions
  local ctx = get_context(bufnr)

  local status = {
    enabled = nes_config and nes_config.enabled or false,
    setup_done = nes.setup_done,
    auto_trigger = nes_config and nes_config.auto_trigger or false,
    current_suggestions = ctx.suggestions and #ctx.suggestions or 0,
    current_suggestion_index = ctx.current_suggestion,
    buffer_id = bufnr,
  }

  return status
end

---@param bufnr? integer
function M.show_status(bufnr)
  local status = M.get_status(bufnr)

  local message = string.format(
    "NES Status:\n"
      .. "  Enabled: %s\n"
      .. "  Setup: %s\n"
      .. "  Auto-trigger: %s\n"
      .. "  Suggestions: %d\n"
      .. "  Current: %s\n"
      .. "  Buffer: %d",
    status.enabled and "ON" or "OFF",
    status.setup_done and "Ready" or "Not initialized",
    status.auto_trigger and "ON" or "OFF",
    status.current_suggestions,
    status.current_suggestion_index and tostring(status.current_suggestion_index) or "None",
    status.buffer_id
  )

  vim.notify(message, vim.log.levels.INFO)
  return status
end

function M.toggle_nes(bufnr)
  local nes_config = config.next_edit_suggestions

  if not nes_config then
    vim.notify("NES: Configuration not found", vim.log.levels.ERROR)
    return
  end

  -- Toggle the enabled state
  nes_config.enabled = not nes_config.enabled

  if nes_config.enabled then
    -- Enable NES
    if not nes.setup_done then
      M.setup()
    end
    vim.notify("NES: Next Edit Suggestions enabled", vim.log.levels.INFO)
    logger.info("NES enabled by user toggle")

    -- Request suggestions for current buffer
    M.request_suggestions(bufnr)
  else
    -- Disable NES
    vim.notify("NES: Next Edit Suggestions disabled", vim.log.levels.WARN)
    logger.info("NES disabled by user toggle")

    -- Clear all current suggestions
    for buf_id, _ in pairs(nes.contexts) do
      clear_suggestions(buf_id)
    end

    -- Optionally teardown (but keep setup_done true for quick re-enable)
    -- M.teardown()
  end
end

-- Event handlers
local function on_text_changed()
  if not nes.setup_done then
    return
  end

  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.enabled and nes_config.auto_trigger then
    M.request_suggestions()
  end
end

local function on_buf_leave(args)
  clear_suggestions(args.buf)
end

local function on_buf_unload(args)
  nes.contexts[args.buf] = nil
end

local function create_autocmds()
  vim.api.nvim_create_augroup(nes.augroup, { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = nes.augroup,
    callback = on_text_changed,
    desc = "[copilot] (nes) text changed",
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = nes.augroup,
    callback = on_buf_leave,
    desc = "[copilot] (nes) buf leave",
  })

  vim.api.nvim_create_autocmd("BufUnload", {
    group = nes.augroup,
    callback = on_buf_unload,
    desc = "[copilot] (nes) buf unload",
  })
end

function M.setup()
  local nes_config = config.next_edit_suggestions
  if not nes_config or not nes_config.enabled then
    return
  end

  if nes.setup_done then
    return
  end

  require("copilot.nes.display").setup()
  require("copilot.nes.keymaps").setup()

  create_autocmds()

  nes.setup_done = true
  logger.info("NES module initialized")
end

function M.teardown()
  if not nes.setup_done then
    return
  end

  vim.api.nvim_clear_autocmds({ group = nes.augroup })
  require("copilot.nes.keymaps").teardown()

  for bufnr, _ in pairs(nes.contexts) do
    clear_suggestions(bufnr)
  end
  nes.contexts = {}

  nes.setup_done = false
end

return M
