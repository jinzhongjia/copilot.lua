local config = require("copilot.config")

local M = {}

local function set_keymap(keymap_config)
  local default_keymaps = require("copilot.config.next_edit_suggestions").default.keymaps
  local keymaps = vim.tbl_extend("force", default_keymaps, keymap_config or {})

  -- Helper function to check if NES has suggestions
  local function has_suggestions()
    local nes_ok, nes = pcall(require, "copilot.nes")
    if not nes_ok or not nes.contexts then
      return false
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local ctx = nes.contexts[bufnr]
    return ctx and ctx.suggestions and #ctx.suggestions > 0
  end

  if keymaps.accept then
    vim.keymap.set("i", keymaps.accept, function()
      if has_suggestions() then
        local nes_ok, nes = pcall(require, "copilot.nes")
        if nes_ok and nes.accept_current_suggestion then
          nes.accept_current_suggestion()
          return
        end
      end
      -- Return the original key if no suggestion
      return keymaps.accept
    end, {
      desc = "[copilot] Accept Next Edit Suggestion",
      silent = true,
      expr = true,
    })
  end

  if keymaps.reject then
    vim.keymap.set("i", keymaps.reject, function()
      if has_suggestions() then
        local nes_ok, nes = pcall(require, "copilot.nes")
        if nes_ok and nes.reject_current_suggestion then
          nes.reject_current_suggestion()
          return ""
        end
      end
      -- Return the original key if no suggestion
      return keymaps.reject
    end, {
      desc = "[copilot] Reject Next Edit Suggestion",
      silent = true,
      expr = true,
    })
  end

  if keymaps.next then
    vim.keymap.set("i", keymaps.next, function()
      if has_suggestions() then
        local nes_ok, nes = pcall(require, "copilot.nes")
        if nes_ok and nes.next_suggestion then
          nes.next_suggestion()
          return ""
        end
      end
      -- Return the original key if no suggestion
      return keymaps.next
    end, {
      desc = "[copilot] Next Edit Suggestion",
      silent = true,
      expr = true,
    })
  end

  if keymaps.prev then
    vim.keymap.set("i", keymaps.prev, function()
      if has_suggestions() then
        local nes_ok, nes = pcall(require, "copilot.nes")
        if nes_ok and nes.prev_suggestion then
          nes.prev_suggestion()
          return ""
        end
      end
      -- Return the original key if no suggestion
      return keymaps.prev
    end, {
      desc = "[copilot] Previous Edit Suggestion",
      silent = true,
      expr = true,
    })
  end

  if keymaps.toggle then
    vim.keymap.set("n", keymaps.toggle, function()
      local nes_ok, nes = pcall(require, "copilot.nes")
      if nes_ok and nes.toggle_nes then
        nes.toggle_nes()
      end
    end, {
      desc = "[copilot] Toggle Next Edit Suggestions",
      silent = true,
    })
  end

  if keymaps.jump then
    vim.keymap.set({"i", "n"}, keymaps.jump, function()
      local nes_ok, nes = pcall(require, "copilot.nes")
      if nes_ok and nes.jump_to_current_suggestion then
        nes.jump_to_current_suggestion()
      end
    end, {
      desc = "[copilot] Jump to Current NES Suggestion",
      silent = true,
    })
  end
end

local function unset_keymap(keymap_config)
  local default_keymaps = require("copilot.config.next_edit_suggestions").default.keymaps
  local keymaps = vim.tbl_extend("force", default_keymaps, keymap_config or {})

  if keymaps.accept then
    pcall(vim.keymap.del, "i", keymaps.accept)
  end

  if keymaps.reject then
    pcall(vim.keymap.del, "i", keymaps.reject)
  end

  if keymaps.next then
    pcall(vim.keymap.del, "i", keymaps.next)
  end

  if keymaps.prev then
    pcall(vim.keymap.del, "i", keymaps.prev)
  end

  if keymaps.toggle then
    pcall(vim.keymap.del, "n", keymaps.toggle)
  end

  if keymaps.jump then
    pcall(vim.keymap.del, "i", keymaps.jump)
    pcall(vim.keymap.del, "n", keymaps.jump)
  end
end

function M.setup()
  local nes_config = config.next_edit_suggestions
  if not nes_config or not nes_config.enabled then
    return
  end

  local keymap_config = nes_config.keymaps
  set_keymap(keymap_config)
end

function M.teardown()
  local nes_config = config.next_edit_suggestions
  if not nes_config then
    return
  end

  local keymap_config = nes_config.keymaps
  unset_keymap(keymap_config)
end

return M
