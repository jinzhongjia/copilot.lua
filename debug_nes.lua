-- Debug script for NES functionality

local function debug_nes()
  print("=== NES Debug Information ===")

  -- 1. Check if copilot client is running
  print("\n[1. Copilot Client Status]")
  local client_ok, client = pcall(require, "copilot.client")
  if client_ok then
    local c = client.get()
    if c then
      print("  OK: Copilot client is running (ID: " .. c.id .. ")")
      print("  Server capabilities:")
      if c.server_capabilities then
        for key, value in pairs(c.server_capabilities) do
          if type(value) == "table" then
            print("    " .. key .. ": [table]")
          else
            print("    " .. key .. ": " .. tostring(value))
          end
        end
      else
        print("    ERROR: No server capabilities found")
      end
    else
      print("  ERROR: Copilot client is not running")
      return
    end
  else
    print("  ERROR: Failed to load copilot client: " .. tostring(client))
    return
  end

  -- 2. Check NES configuration
  print("\n[2. NES Configuration]")
  local config_ok, config = pcall(require, "copilot.config")
  if config_ok and config.next_edit_suggestions then
    local nes_config = config.next_edit_suggestions
    print("  OK: NES config found")
    print("  Enabled: " .. tostring(nes_config.enabled))
    print("  Auto-trigger: " .. tostring(nes_config.auto_trigger))
    print("  Debounce: " .. tostring(nes_config.debounce) .. "ms")
    print("  Verbose notifications: " .. tostring(nes_config.verbose_notifications))
  else
    print("  ERROR: NES config not found")
    return
  end

  -- 3. Check NES module status
  print("\n[3. NES Module Status]")
  local nes_ok, nes = pcall(require, "copilot.nes")
  if nes_ok then
    print("  OK: NES module loaded")
    local status = nes.get_status()
    print("  Setup done: " .. tostring(status.setup_done))
    print("  Current buffer: " .. status.buffer_id)
    print("  Current suggestions: " .. status.current_suggestions)
    print("  Current index: " .. tostring(status.current_suggestion_index))
  else
    print("  ERROR: Failed to load NES module: " .. tostring(nes))
    return
  end

  -- 4. Check current buffer context
  print("\n[4. Buffer Context]")
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  print("  Buffer: " .. bufnr)
  print("  Filetype: " .. filetype)
  print("  Lines: " .. line_count)

  -- Check if filetype is excluded
  local nes_config = config.next_edit_suggestions
  if nes_config and nes_config.filter and nes_config.filter.exclude_filetypes then
    local excluded = vim.tbl_contains(nes_config.filter.exclude_filetypes, filetype)
    print("  Filetype excluded: " .. tostring(excluded))
  end

  -- 5. Test LSP communication
  print("\n[5. LSP Communication Test]")
  local c = client.get()
  if c then
    print("  Testing LSP server communication...")

    -- Test basic server communication
    local api = require("copilot.api")
    api.check_status(c, function(err, result)
      if err then
        print("  ERROR: LSP server error: " .. vim.inspect(err))
      else
        print("  OK: LSP server responding: " .. vim.inspect(result))
      end
    end)

    -- Check server capabilities for Next Edit Suggestions
    if c.server_capabilities and c.server_capabilities.experimental then
      print("  Experimental capabilities: " .. vim.inspect(c.server_capabilities.experimental))
    else
      print("  WARNING: No experimental capabilities found (NES may not be supported)")
    end
  end

  -- 6. Manual trigger test
  print("\n[6. Manual Trigger Test]")
  print("  Attempting to request suggestions...")
  if nes_ok then
    nes.request_suggestions()
    print("  Request sent")

    -- Check after a delay
    vim.defer_fn(function()
      local new_status = nes.get_status()
      print("  After request - Suggestions: " .. new_status.current_suggestions)
      if new_status.current_suggestions == 0 then
        print("  WARNING: No suggestions received. This could mean:")
        print("     - The LSP server doesn't support NES")
        print("     - The current context doesn't warrant suggestions")
        print("     - There's a communication issue")
      end
    end, 1000)
  end

  print("\n=== End NES Debug ===")
end

-- Export the function
return { debug_nes = debug_nes }
