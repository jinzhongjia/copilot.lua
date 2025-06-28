-- Test file for Next Edit Suggestions integration
-- NES 集成测试文件

local nes = require("copilot.nes")
local config = require("copilot.config")

describe("Next Edit Suggestions Integration", function()
  before_each(function()
    -- Reset configuration before each test
    config.next_edit_suggestions = require("copilot.config.next_edit_suggestions").default
  end)

  describe("Configuration", function()
    it("should have default NES configuration", function()
      local nes_config = config.next_edit_suggestions
      assert.is_not_nil(nes_config)
      assert.is_false(nes_config.enabled) -- Default is disabled
      assert.is_true(nes_config.auto_trigger)
      assert.equals(500, nes_config.debounce)
      assert.equals("float", nes_config.display.type)
    end)

    it("should validate NES configuration", function()
      local valid_config = {
        enabled = true,
        auto_trigger = true,
        debounce = 300,
        display = {
          type = "float",
          max_suggestions = 3,
          auto_show = true,
          timeout = 5000,
        },
        keymaps = {
          accept = "<C-y>",
          reject = "<C-n>",
          next = "<C-]>",
          prev = "<C-[>",
          toggle = "<leader>cn",
        },
        filter = {
          min_confidence = 0.5,
          max_suggestions_per_line = 1,
          exclude_filetypes = {},
        },
      }

      assert.has_no.errors(function()
        require("copilot.config.next_edit_suggestions").validate(valid_config)
      end)
    end)

    it("should reject invalid NES configuration", function()
      local invalid_config = {
        enabled = "not_boolean", -- Invalid type
        auto_trigger = true,
        debounce = 300,
        display = {
          type = "invalid_type", -- Invalid display type
          max_suggestions = 3,
          auto_show = true,
          timeout = 5000,
        },
        keymaps = {
          accept = "<C-y>",
          reject = "<C-n>",
          next = "<C-]>",
          prev = "<C-[>",
          toggle = "<leader>cn",
        },
        filter = {
          min_confidence = 1.5, -- Invalid range
          max_suggestions_per_line = 1,
          exclude_filetypes = {},
        },
      }

      assert.has.errors(function()
        require("copilot.config.next_edit_suggestions").validate(invalid_config)
      end)
    end)
  end)

  describe("NES Module", function()
    it("should be loadable", function()
      assert.is_not_nil(nes)
      assert.is_function(nes.setup)
      assert.is_function(nes.teardown)
      assert.is_function(nes.handle_suggestions)
    end)

    it("should have all required functions", function()
      assert.is_function(nes.request_suggestions)
      assert.is_function(nes.accept_current_suggestion)
      assert.is_function(nes.reject_current_suggestion)
      assert.is_function(nes.next_suggestion)
      assert.is_function(nes.prev_suggestion)
      assert.is_function(nes.toggle_nes)
    end)

    it("should handle suggestion data correctly", function()
      local mock_result = {
        suggestions = {
          {
            id = "test_suggestion_1",
            range = {
              start = { line = 0, character = 0 },
              ["end"] = { line = 0, character = 10 },
            },
            newText = "new code",
            description = "Test suggestion",
            confidence = 0.8,
          },
        },
      }

      local bufnr = vim.api.nvim_create_buf(false, true)

      -- This should not error
      assert.has_no.errors(function()
        nes.handle_suggestions(mock_result, 1, bufnr)
      end)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("Display Module", function()
    it("should be loadable", function()
      local display = require("copilot.nes.display")
      assert.is_not_nil(display)
      assert.is_function(display.setup)
      assert.is_function(display.show_suggestions)
      assert.is_function(display.clear_display)
    end)
  end)

  describe("Keymaps Module", function()
    it("should be loadable", function()
      local keymaps = require("copilot.nes.keymaps")
      assert.is_not_nil(keymaps)
      assert.is_function(keymaps.setup)
      assert.is_function(keymaps.teardown)
    end)
  end)

  describe("API Integration", function()
    it("should have NES API functions", function()
      local api = require("copilot.api")
      assert.is_function(api.nes_accept_suggestion)
      assert.is_function(api.nes_reject_suggestion)
    end)
  end)

  describe("LSP Integration", function()
    it("should include NES commands in workspace commands", function()
      -- Mock config with NES enabled
      config.next_edit_suggestions.enabled = true

      local nodejs = require("copilot.lsp.nodejs")
      local commands = nodejs.get_workspace_commands()

      assert.is_true(vim.tbl_contains(commands, "github.copilot.didAcceptNextEditSuggestionItem"))
      assert.is_true(vim.tbl_contains(commands, "github.copilot.didRejectNextEditSuggestionItem"))
    end)

    it("should include NES handlers", function()
      -- Mock config with NES enabled
      config.next_edit_suggestions.enabled = true

      local handlers = require("copilot.client.handlers")
      local handler_map = handlers.get_handlers()

      assert.is_not_nil(handler_map["textDocument/publishNextEditSuggestions"])
      assert.is_function(handler_map["textDocument/publishNextEditSuggestions"])
    end)
  end)
end)
