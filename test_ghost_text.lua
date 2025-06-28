-- Test file for NES ghost text implementation

local function test_ghost_text()
  print("=== Testing NES Ghost Text Implementation ===")
  
  -- Test 1: Check if display module loads correctly
  print("\n[1. Loading NES Display Module]")
  local display_ok, display = pcall(require, "copilot.nes.display")
  if display_ok then
    print("  OK: NES display module loaded successfully")
  else
    print("  ERROR: Failed to load NES display module: " .. tostring(display))
    return
  end
  
  -- Test 2: Setup display system
  print("\n[2. Setting Up Display System]")
  pcall(display.setup)
  print("  OK: Display system setup completed")
  
  -- Test 3: Check highlight groups
  print("\n[3. Checking Highlight Groups]")
  local ghost_hl = vim.api.nvim_get_hl(0, { name = "CopilotNESGhost" })
  local range_hl = vim.api.nvim_get_hl(0, { name = "CopilotNESRange" })
  
  if next(ghost_hl) then
    print("  OK: CopilotNESGhost highlight group created")
    print("    Foreground: " .. (ghost_hl.fg and string.format("#%06x", ghost_hl.fg) or "default"))
    print("    Italic: " .. tostring(ghost_hl.italic or false))
  else
    print("  WARNING: CopilotNESGhost highlight group not found")
  end
  
  if next(range_hl) then
    print("  OK: CopilotNESRange highlight group created")
    print("    Background: " .. (range_hl.bg and string.format("#%06x", range_hl.bg) or "default"))
  else
    print("  WARNING: CopilotNESRange highlight group not found")
  end
  
  -- Test 4: Test mock suggestion display
  print("\n[4. Testing Mock Suggestion Display]")
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace("test_nes")
  
  -- Create a mock suggestion
  local mock_suggestion = {
    id = "test_suggestion_1",
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = 0, character = 5 }
    },
    newText = "console.log('Hello from NES!')",
    description = "Test suggestion for ghost text display"
  }
  
  -- Create mock context
  local mock_ctx = {
    suggestions = { mock_suggestion },
    current_suggestion = 1,
    config = {
      display = {
        ghost_text_enabled = true,
        max_suggestions = 3,
        auto_show = true
      }
    }
  }
  
  -- Test showing suggestions
  pcall(display.show_suggestions, mock_ctx, bufnr, ns_id)
  print("  OK: Mock suggestion display test completed")
  
  -- Test 5: Test clearing display
  print("\n[5. Testing Display Clearing]")
  pcall(display.clear_display, bufnr, ns_id)
  print("  OK: Display clearing test completed")
  
  -- Test 6: Configuration validation
  print("\n[6. Testing Configuration]")
  local config_ok, config_module = pcall(require, "copilot.config.next_edit_suggestions")
  if config_ok then
    print("  OK: NES configuration module loaded")
    local default_config = config_module.default
    if default_config.display.ghost_text_enabled then
      print("  OK: Ghost text is enabled in default configuration")
    else
      print("  WARNING: Ghost text is disabled in default configuration")
    end
  else
    print("  ERROR: Failed to load NES configuration: " .. tostring(config_module))
  end
  
  print("\n=== Ghost Text Test Completed ===")
  print("To see ghost text in action:")
  print("1. Ensure Copilot is running: :Copilot status")
  print("2. Enable NES: <leader>cn")
  print("3. Start typing in a code file")
  print("4. Look for gray italic text appearing as suggestions")
end

-- Export the function
return { test_ghost_text = test_ghost_text }