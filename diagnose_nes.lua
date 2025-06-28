-- Comprehensive NES diagnosis tool

local function diagnose_nes()
  print("=== NES Comprehensive Diagnosis ===")
  
  -- Step 1: Check Copilot client and server capabilities
  print("\n[1. Copilot Client & Server Analysis]")
  local client_ok, client = pcall(require, "copilot.client")
  if not client_ok then
    print("  ERROR: Cannot load copilot client module")
    return
  end
  
  local c = client.get()
  if not c then
    print("  ERROR: Copilot client not running")
    print("  SOLUTION: Run :Copilot setup or :Copilot auth")
    return
  end
  
  print("  OK: Copilot client running (ID: " .. c.id .. ")")
  
  -- Check server capabilities
  if c.server_capabilities then
    print("  Server capabilities found:")
    
    -- Check for experimental capabilities (where NES might be)
    if c.server_capabilities.experimental then
      print("    Experimental capabilities: " .. vim.inspect(c.server_capabilities.experimental))
    else
      print("    WARNING: No experimental capabilities found")
    end
    
    -- Check for relevant capabilities
    local relevant_caps = {
      "textDocumentSync",
      "completionProvider", 
      "workspace",
    }
    
    for _, cap in ipairs(relevant_caps) do
      if c.server_capabilities[cap] then
        print("    " .. cap .. ": present")
      end
    end
  else
    print("  WARNING: No server capabilities found")
  end
  
  -- Step 2: Check LSP server version
  print("\n[2. LSP Server Version Check]")
  local api = require("copilot.api")
  api.get_version(c, function(err, result)
    if err then
      print("  ERROR: Cannot get server version: " .. vim.inspect(err))
    else
      print("  Server version: " .. vim.inspect(result))
      -- NES typically requires newer versions
      if result and result.version then
        print("  INFO: NES requires Copilot LSP version 1.190.0 or newer")
      end
    end
  end)
  
  -- Step 3: Check NES configuration and setup
  print("\n[3. NES Configuration Check]")
  local config_ok, config = pcall(require, "copilot.config")
  if config_ok and config.next_edit_suggestions then
    local nes_config = config.next_edit_suggestions
    print("  NES config found:")
    print("    Enabled: " .. tostring(nes_config.enabled))
    print("    Auto-trigger: " .. tostring(nes_config.auto_trigger))
    print("    Debounce: " .. tostring(nes_config.debounce) .. "ms")
    
    if not nes_config.enabled then
      print("  WARNING: NES is disabled. Enable with <leader>cn")
    end
  else
    print("  ERROR: NES configuration not found")
    return
  end
  
  -- Step 4: Check NES module initialization
  print("\n[4. NES Module Status]")
  local nes_ok, nes = pcall(require, "copilot.nes")
  if nes_ok then
    local status = nes.get_status()
    print("  NES module status:")
    print("    Setup done: " .. tostring(status.setup_done))
    print("    Current buffer: " .. status.buffer_id)
    print("    Suggestions count: " .. status.current_suggestions)
    
    if not status.setup_done then
      print("  WARNING: NES not initialized. Enable NES first.")
    end
  else
    print("  ERROR: Cannot load NES module")
    return
  end
  
  -- Step 5: Check LSP handlers
  print("\n[5. LSP Handler Registration]")
  local handlers_ok, handlers = pcall(require, "copilot.client.handlers")
  if handlers_ok then
    local handler_list = handlers.get_handlers()
    if handler_list["textDocument/publishNextEditSuggestions"] then
      print("  OK: NES LSP handler registered")
    else
      print("  WARNING: NES LSP handler not found")
      print("  This could mean:")
      print("    1. NES is disabled in config")
      print("    2. Handler registration failed")
    end
  else
    print("  ERROR: Cannot check LSP handlers")
  end
  
  -- Step 6: Simulate NES functionality
  print("\n[6. NES Simulation Test]")
  if nes_ok and config.next_edit_suggestions.enabled then
    print("  Creating mock NES suggestion...")
    
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    -- Create a realistic mock suggestion
    local mock_suggestion = {
      id = "diagnostic_test_001",
      range = {
        start = { line = cursor_pos[1] - 1, character = cursor_pos[2] },
        ["end"] = { line = cursor_pos[1] - 1, character = cursor_pos[2] + 10 }
      },
      newText = "// TODO: Implement this function",
      description = "Mock NES suggestion for testing",
      confidence = 0.9
    }
    
    -- Simulate LSP response
    local mock_result = {
      suggestions = { mock_suggestion }
    }
    
    -- Test the handler
    pcall(nes.handle_suggestions, mock_result, c.id, bufnr)
    
    -- Check if suggestion was processed
    vim.defer_fn(function()
      local new_status = nes.get_status(bufnr)
      if new_status.current_suggestions > 0 then
        print("  SUCCESS: Mock suggestion created and displayed!")
        print("  You should see ghost text: '// TODO: Implement this function'")
        print("  Try using:")
        print("    <C-j> to accept")
        print("    <C-k> to reject") 
        print("    <C-g> to jump")
      else
        print("  WARNING: Mock suggestion not displayed")
        print("  This could indicate display issues")
      end
    end, 500)
  else
    print("  SKIPPED: NES not enabled or available")
  end
  
  -- Step 7: Real-world test suggestions
  print("\n[7. Real-world Test Scenarios]")
  print("  To trigger real NES suggestions, try these scenarios:")
  print("  1. JavaScript/TypeScript:")
  print("     - Type 'console.' and wait")
  print("     - Create a function with missing return statement")
  print("     - Add error handling to try-catch blocks")
  print()
  print("  2. Python:")
  print("     - Import statements (import )")
  print("     - Function definitions with missing docstrings")
  print("     - Exception handling")
  print()
  print("  3. General:")
  print("     - Open an existing file with incomplete code")
  print("     - Add comments or documentation")
  print("     - Refactor existing functions")
  
  print("\n=== Diagnosis Complete ===")
  print("\nNext steps:")
  print("1. Ensure Copilot is authenticated: :Copilot status")
  print("2. Enable NES: <leader>cn")
  print("3. Try test scenarios above")
  print("4. Check for ghost text with gray italic styling")
  print("5. Use debug commands: :lua require('copilot.nes').show_status()")
end

-- Export function
return { diagnose_nes = diagnose_nes }