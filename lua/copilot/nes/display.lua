local logger = require("copilot.logger")

local M = {}

local nes_display = {
  highlight_groups = {
    ghost_text = "CopilotNESGhost",
    ghost_text_remote = "CopilotNESGhostRemote",
    range_highlight = "CopilotNESRange",
    location_indicator = "CopilotNESLocation",
  },
  -- Track current ghost text state
  current_ghost = {
    bufnr = nil,
    line = nil,
    col = nil,
    extmark_id = nil,
  },
}

local function create_highlight_groups()
  -- Ghost text highlight - make it distinct from regular completion
  -- Using italic and dimmed style to differentiate from normal Copilot suggestions
  -- Adapts better to different colorschemes by linking to existing highlight groups
  vim.api.nvim_set_hl(0, nes_display.highlight_groups.ghost_text, {
    link = "Comment",
    italic = true,
    default = true,
  })

  -- Ghost text for remote suggestions (not at cursor)
  vim.api.nvim_set_hl(0, nes_display.highlight_groups.ghost_text_remote, {
    link = "Comment",
    italic = true,
    bold = true,
    default = true,
  })

  -- Range highlight for the text that will be replaced
  -- Links to existing highlight group for better theme compatibility
  vim.api.nvim_set_hl(0, nes_display.highlight_groups.range_highlight, {
    link = "CursorLine",
    default = true,
  })

  -- Location indicator for remote suggestions
  vim.api.nvim_set_hl(0, nes_display.highlight_groups.location_indicator, {
    link = "WarningMsg",
    default = true,
  })
end

---@param bufnr integer
---@param ns_id integer
local function clear_highlights(bufnr, ns_id)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

---@param bufnr integer
---@param ns_id integer
local function clear_ghost_text(bufnr, ns_id)
  if nes_display.current_ghost.extmark_id then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, nes_display.current_ghost.extmark_id)
    nes_display.current_ghost.extmark_id = nil
  end
  nes_display.current_ghost.bufnr = nil
  nes_display.current_ghost.line = nil
  nes_display.current_ghost.col = nil
end

---@param suggestion table
---@param bufnr integer
---@param ns_id integer
local function show_ghost_text(suggestion, bufnr, ns_id)
  local range = suggestion.range
  if not range or not range.start then
    return
  end

  local start_line = range.start.line
  local start_col = range.start.character
  local new_text = suggestion.newText or ""

  -- Clear any existing ghost text
  clear_ghost_text(bufnr, ns_id)

  -- Get current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor_pos[1] - 1 -- Convert to 0-based
  local cursor_col = cursor_pos[2]

  -- Check if suggestion is at current cursor position
  local is_at_cursor = (cursor_line == start_line and math.abs(cursor_col - start_col) <= 10)
  
  -- For suggestions not at cursor, we'll show them with different styling

  -- Split the new text into lines
  local text_lines = vim.split(new_text, "\n", { plain = true })
  
  if #text_lines == 0 then
    return
  end

  -- Choose highlight group based on location
  local ghost_hl = is_at_cursor and nes_display.highlight_groups.ghost_text 
                                 or nes_display.highlight_groups.ghost_text_remote

  -- For single line suggestions, show as inline ghost text
  if #text_lines == 1 then
    local ghost_text = text_lines[1]
    if ghost_text and ghost_text ~= "" then
      -- Add location indicator for remote suggestions
      if not is_at_cursor then
        ghost_text = "[L" .. (start_line + 1) .. "] " .. ghost_text
      end
      
      -- Show ghost text at suggestion position
      local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, start_col, {
        virt_text = { { ghost_text, ghost_hl } },
        virt_text_pos = "overlay",
        priority = is_at_cursor and 100 or 90,
      })
      
      nes_display.current_ghost.extmark_id = extmark_id
      nes_display.current_ghost.bufnr = bufnr
      nes_display.current_ghost.line = start_line
      nes_display.current_ghost.col = start_col
    end
  else
    -- For multi-line suggestions, show first line as ghost text and indicate more lines
    local first_line = text_lines[1] or ""
    local location_prefix = is_at_cursor and "" or "[L" .. (start_line + 1) .. "] "
    local ghost_text = location_prefix .. first_line .. " ... [" .. (#text_lines - 1) .. " more lines]"
    
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, start_col, {
      virt_text = { { ghost_text, ghost_hl } },
      virt_text_pos = "overlay",
      priority = is_at_cursor and 100 or 90,
    })
    
    nes_display.current_ghost.extmark_id = extmark_id
    nes_display.current_ghost.bufnr = bufnr
    nes_display.current_ghost.line = start_line
    nes_display.current_ghost.col = start_col
  end
end

---@param suggestion table
---@param bufnr integer
---@param ns_id integer
local function highlight_suggestion_range(suggestion, bufnr, ns_id)
  local range = suggestion.range
  if not range or not range.start or not range["end"] then
    return
  end

  -- Highlight the range that will be modified
  local start_line = range.start.line
  local start_col = range.start.character
  local end_line = range["end"].line
  local end_col = range["end"].character

  -- Add range highlight
  if start_line == end_line then
    -- Single line range
    vim.api.nvim_buf_add_highlight(
      bufnr,
      ns_id,
      nes_display.highlight_groups.range_highlight,
      start_line,
      start_col,
      end_col
    )
  else
    -- Multi-line range
    for line = start_line, end_line do
      local line_start_col = (line == start_line) and start_col or 0
      local line_end_col = (line == end_line) and end_col or -1
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns_id,
        nes_display.highlight_groups.range_highlight,
        line,
        line_start_col,
        line_end_col
      )
    end
  end
end

---@param ctx table NES context
---@param bufnr integer
---@param ns_id integer
function M.show_suggestions(ctx, bufnr, ns_id)
  if not ctx.suggestions or #ctx.suggestions == 0 or not ctx.current_suggestion then
    M.clear_display(bufnr, ns_id)
    return
  end

  logger.trace("NES display show suggestions", ctx)

  local current_suggestion = ctx.suggestions[ctx.current_suggestion]

  -- Clear previous highlights and ghost text
  clear_highlights(bufnr, ns_id)
  clear_ghost_text(bufnr, ns_id)

  -- Show ghost text for the current suggestion
  show_ghost_text(current_suggestion, bufnr, ns_id)

  -- Highlight the suggestion range
  highlight_suggestion_range(current_suggestion, bufnr, ns_id)
end

---@param bufnr? integer
---@param ns_id? integer
function M.clear_display(bufnr, ns_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if ns_id then
    clear_highlights(bufnr, ns_id)
    clear_ghost_text(bufnr, ns_id)
  end
end

function M.setup()
  create_highlight_groups()

  -- Auto-clear ghost text when cursor moves significantly
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if nes_display.current_ghost.bufnr == bufnr then
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local cursor_line = cursor_pos[1] - 1 -- Convert to 0-based
        local cursor_col = cursor_pos[2]
        
        -- Clear ghost text if cursor moved too far from the suggestion
        if nes_display.current_ghost.line and 
           (math.abs(cursor_line - nes_display.current_ghost.line) > 1 or
            (cursor_line == nes_display.current_ghost.line and 
             math.abs(cursor_col - nes_display.current_ghost.col) > 50)) then
          local nes = require("copilot.nes")
          clear_ghost_text(bufnr, nes.ns_id)
        end
      end
    end,
  })

  -- Clear ghost text when leaving insert mode
  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if nes_display.current_ghost.bufnr == bufnr then
        local nes = require("copilot.nes")
        clear_ghost_text(bufnr, nes.ns_id)
      end
    end,
  })
end

return M