-- Debug script to check current keymaps

local function check_keymaps()
  print("=== Current Keymaps Debug ===")

  -- Check insert mode keymaps
  local insert_keymaps = vim.api.nvim_get_keymap("i")
  print("\n[Insert Mode Keymaps]")

  local nes_keymaps = {}
  for _, keymap in ipairs(insert_keymaps) do
    if keymap.desc and string.match(keymap.desc, "copilot.*Edit") then
      table.insert(nes_keymaps, keymap)
      print(string.format("  %s -> %s", keymap.lhs, keymap.desc))
    end
  end

  if #nes_keymaps == 0 then
    print("  No NES keymaps found in insert mode")
  end

  -- Check normal mode keymaps
  local normal_keymaps = vim.api.nvim_get_keymap("n")
  print("\n[Normal Mode Keymaps]")

  local nes_normal_keymaps = {}
  for _, keymap in ipairs(normal_keymaps) do
    if keymap.desc and string.match(keymap.desc, "copilot.*Edit") then
      table.insert(nes_normal_keymaps, keymap)
      print(string.format("  %s -> %s", keymap.lhs, keymap.desc))
    end
  end

  if #nes_normal_keymaps == 0 then
    print("  No NES keymaps found in normal mode")
  end

  -- Check if ESC is mapped
  print("\n[ESC Keymap Check]")
  local esc_found = false
  for _, keymap in ipairs(insert_keymaps) do
    if keymap.lhs == "<Esc>" or keymap.lhs == "^[" then
      print(string.format("  ESC is mapped: %s -> %s", keymap.lhs, keymap.desc or "no description"))
      esc_found = true
    end
  end

  if not esc_found then
    print("  ESC is not remapped (this is normal)")
  end

  -- Check NES status
  print("\n[NES Status]")
  local nes_ok, nes = pcall(require, "copilot.nes")
  if nes_ok then
    print("  NES module loaded: OK")
    if nes.contexts then
      local bufnr = vim.api.nvim_get_current_buf()
      local ctx = nes.contexts[bufnr]
      if ctx and ctx.suggestions then
        print(string.format("  Current buffer suggestions: %d", #ctx.suggestions))
      else
        print("  Current buffer suggestions: 0")
      end
    else
      print("  NES contexts not initialized")
    end
  else
    print("  NES module failed to load: " .. tostring(nes))
  end

  -- Check config
  print("\n[NES Config]")
  local config_ok, config = pcall(require, "copilot.config")
  if config_ok and config.next_edit_suggestions then
    print("  NES enabled: " .. tostring(config.next_edit_suggestions.enabled))
    if config.next_edit_suggestions.keymaps then
      print("  Accept key: " .. (config.next_edit_suggestions.keymaps.accept or "not set"))
      print("  Reject key: " .. (config.next_edit_suggestions.keymaps.reject or "not set"))
    end
  else
    print("  NES config not found")
  end

  print("\n=== End Debug ===")
end

-- Export the function
return { check_keymaps = check_keymaps }
