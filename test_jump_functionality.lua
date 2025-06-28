-- Test file for NES jump functionality

local function test_jump_functionality()
  print("=== Testing NES Jump Functionality ===")
  
  -- Test 1: Check if NES module loads correctly with jump function
  print("\n[1. Loading NES Module]")
  local nes_ok, nes = pcall(require, "copilot.nes")
  if nes_ok then
    print("  OK: NES module loaded successfully")
    if nes.jump_to_current_suggestion then
      print("  OK: jump_to_current_suggestion function available")
    else
      print("  ERROR: jump_to_current_suggestion function not found")
      return
    end
  else
    print("  ERROR: Failed to load NES module: " .. tostring(nes))
    return
  end
  
  -- Test 2: Check jump keymap configuration
  print("\n[2. Checking Jump Keymap Configuration]")
  local config_ok, config_module = pcall(require, "copilot.config.next_edit_suggestions")
  if config_ok then
    local default_config = config_module.default
    if default_config.keymaps.jump then
      print("  OK: Jump keymap configured: " .. default_config.keymaps.jump)
    else
      print("  ERROR: Jump keymap not configured")
    end
  else
    print("  ERROR: Failed to load NES configuration")
  end
  
  -- Test 3: Test display system with remote suggestions
  print("\n[3. Testing Remote Suggestion Display]")
  local display_ok, display = pcall(require, "copilot.nes.display")
  if display_ok then
    print("  OK: Display module loaded")
    
    -- Check if remote highlight groups are created
    pcall(display.setup)
    local ghost_remote_hl = vim.api.nvim_get_hl(0, { name = "CopilotNESGhostRemote" })
    if next(ghost_remote_hl) then
      print("  OK: CopilotNESGhostRemote highlight group created")
    else
      print("  WARNING: CopilotNESGhostRemote highlight group not found")
    end
    
    local location_hl = vim.api.nvim_get_hl(0, { name = "CopilotNESLocation" })
    if next(location_hl) then
      print("  OK: CopilotNESLocation highlight group created")
    else
      print("  WARNING: CopilotNESLocation highlight group not found")
    end
  else
    print("  ERROR: Failed to load display module")
  end
  
  -- Test 4: Simulate jump functionality
  print("\n[4. Testing Jump Functionality]")
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Create a mock suggestion at a different line
  local mock_suggestion = {
    id = "test_jump_suggestion",
    range = {
      start = { line = 10, character = 5 }, -- Line 11 in 1-based
      ["end"] = { line = 10, character = 20 }
    },
    newText = "test_remote_suggestion()",
    description = "Test suggestion for jump functionality"
  }
  
  -- Create mock context with remote suggestion
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
  
  -- Store original cursor position
  local original_pos = vim.api.nvim_win_get_cursor(0)
  print("  Original cursor position: line " .. original_pos[1] .. ", col " .. original_pos[2])
  
  -- Test the jump function with mock data
  -- We'll simulate this by directly calling the jump function
  if nes.contexts then
    nes.contexts[bufnr] = mock_ctx
    
    pcall(nes.jump_to_current_suggestion, bufnr)
    
    local new_pos = vim.api.nvim_win_get_cursor(0)
    print("  After jump cursor position: line " .. new_pos[1] .. ", col " .. new_pos[2])
    
    if new_pos[1] == 11 and new_pos[2] == 5 then
      print("  OK: Jump functionality working correctly")
    else
      print("  WARNING: Jump may not have worked as expected")
    end
    
    -- Restore original position
    vim.api.nvim_win_set_cursor(0, original_pos)
    
    -- Clean up
    nes.contexts[bufnr] = nil
  else
    print("  WARNING: Cannot test jump without NES contexts")
  end
  
  print("\n=== Jump Functionality Test Completed ===")
  print("Enhanced NES features:")
  print("1. Suggestions can now appear anywhere in the buffer")
  print("2. Remote suggestions show with [L#] line indicators") 
  print("3. Use <C-g> to jump to current suggestion location")
  print("4. Accept suggestion automatically jumps to location")
  print("5. Bold italic styling for remote suggestions")
end

-- Export the function
return { test_jump_functionality = test_jump_functionality }