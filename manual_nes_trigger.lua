-- Manual NES Trigger for Testing
-- This allows you to manually create NES suggestions for testing

local function trigger_test_suggestions()
  print("=== Manual NES Trigger ===")
  
  -- Check if NES is available
  local nes_ok, nes = pcall(require, "copilot.nes")
  if not nes_ok then
    print("ERROR: Cannot load NES module")
    return
  end
  
  local client_ok, client = pcall(require, "copilot.client")
  if not client_ok then
    print("ERROR: Cannot load copilot client")
    return
  end
  
  local c = client.get()
  if not c then
    print("ERROR: Copilot client not running. Start with :Copilot setup")
    return
  end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1] - 1 -- Convert to 0-based
  local current_col = cursor_pos[2]
  
  -- Create test suggestions at different locations
  local test_suggestions = {
    {
      id = "nes_test_001",
      range = {
        start = { line = current_line, character = current_col },
        ["end"] = { line = current_line, character = current_col + 5 }
      },
      newText = "console.log('Hello NES!')",
      description = "Test suggestion at cursor",
      confidence = 0.95
    },
    {
      id = "nes_test_002", 
      range = {
        start = { line = current_line + 2, character = 2 },
        ["end"] = { line = current_line + 2, character = 10 }
      },
      newText = "// TODO: Implement this feature",
      description = "Test remote suggestion",
      confidence = 0.85
    },
    {
      id = "nes_test_003",
      range = {
        start = { line = current_line + 5, character = 0 },
        ["end"] = { line = current_line + 5, character = 0 }
      },
      newText = "function testFunction() {\n  return 'test';\n}",
      description = "Multi-line suggestion",
      confidence = 0.90
    }
  }
  
  -- Create mock LSP result
  local mock_result = {
    suggestions = test_suggestions
  }
  
  print("Creating " .. #test_suggestions .. " test suggestions...")
  print("Cursor position: line " .. (current_line + 1) .. ", col " .. current_col)
  
  -- Trigger NES with mock data
  nes.handle_suggestions(mock_result, c.id, bufnr)
  
  print("\nTest suggestions created! You should see:")
  print("1. Local suggestion (normal italic): 'console.log('Hello NES!')'")
  print("2. Remote suggestion (bold italic): '[L" .. (current_line + 3) .. "] // TODO: Implement this feature'")
  print("3. Multi-line suggestion: 'function testFunction() ... [2 more lines]'")
  
  print("\nUse these controls:")
  print("  <C-l> / <C-h> - Navigate between suggestions")
  print("  <C-g> - Jump to current suggestion")
  print("  <C-j> - Accept suggestion (will jump and apply)")
  print("  <C-k> - Reject suggestion")
  
  -- Show current status
  vim.defer_fn(function()
    local status = nes.get_status(bufnr)
    print("\nCurrent NES status:")
    print("  Active suggestions: " .. status.current_suggestions)
    print("  Current index: " .. tostring(status.current_suggestion_index))
  end, 100)
end

local function clear_test_suggestions()
  print("=== Clearing Test Suggestions ===")
  
  local nes_ok, nes = pcall(require, "copilot.nes")
  if nes_ok then
    local bufnr = vim.api.nvim_get_current_buf()
    require("copilot.nes.display").clear_display(bufnr, nes.ns_id)
    
    -- Clear context
    if nes.contexts and nes.contexts[bufnr] then
      nes.contexts[bufnr].suggestions = {}
      nes.contexts[bufnr].current_suggestion = nil
    end
    
    print("Test suggestions cleared")
  else
    print("ERROR: Cannot load NES module")
  end
end

local function show_nes_keymaps()
  print("=== NES Keymaps Reference ===")
  
  local config_ok, config = pcall(require, "copilot.config")
  if config_ok and config.next_edit_suggestions then
    local keymaps = config.next_edit_suggestions.keymaps
    print("Current NES keybindings:")
    print("  Accept:   " .. (keymaps.accept or "not set"))
    print("  Reject:   " .. (keymaps.reject or "not set"))
    print("  Next:     " .. (keymaps.next or "not set"))
    print("  Previous: " .. (keymaps.prev or "not set"))
    print("  Jump:     " .. (keymaps.jump or "not set"))
    print("  Toggle:   " .. (keymaps.toggle or "not set"))
  else
    print("ERROR: Cannot load NES configuration")
  end
end

-- Export functions
return {
  trigger_test_suggestions = trigger_test_suggestions,
  clear_test_suggestions = clear_test_suggestions,
  show_nes_keymaps = show_nes_keymaps,
}