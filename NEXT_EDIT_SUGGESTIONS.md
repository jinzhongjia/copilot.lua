# Next Edit Suggestions Integration

本文档介绍如何在 zbirenbaum/copilot.lua 中使用集成的 Next Edit Suggestions (NES) 功能。

## 功能概述

Next Edit Suggestions 是 GitHub Copilot Language Server 的一项创新功能，专门用于智能编辑现有代码。与传统的代码自动补全不同，NES 基于上下文感知的预测性编辑，能够预测开发者下一步可能需要的代码修改。

### 主要特点

- **智能预测性编辑**: 基于代码上下文和开发者行为模式的智能编辑建议
- **多场景适用**: 错误修复、代码重构、变量重命名、逻辑优化等
- **上下文感知**: 充分利用文件内容、项目结构、编程语言特性
- **非侵入式集成**: 与现有代码补全功能并行工作

## 配置

### 基本配置

```lua
require("copilot").setup({
  next_edit_suggestions = {
    enabled = true,
    auto_trigger = true,
    debounce = 500,
    display = {
      type = "float",        -- "float" | "inline" | "both"
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
      exclude_filetypes = { "help", "alpha", "dashboard" },
    },
  },
})
```

### 配置选项说明

#### 基本选项

- `enabled`: 是否启用 NES 功能（默认：false）
- `auto_trigger`: 是否自动触发建议（默认：true）
- `debounce`: 防抖延迟时间，单位毫秒（默认：500）

#### 显示选项 (`display`)

- `type`: 显示类型
  - `"float"`: 浮动窗口显示
  - `"inline"`: 内联高亮显示
  - `"both"`: 同时使用两种显示方式
- `max_suggestions`: 最大建议数量（默认：3）
- `auto_show`: 是否自动显示建议（默认：true）
- `timeout`: 建议超时时间，单位毫秒（默认：5000）

#### 键盘映射 (`keymaps`)

- `accept`: 接受当前建议（默认：`<C-y>`）
- `reject`: 拒绝当前建议（默认：`<C-n>`）
- `next`: 切换到下一个建议（默认：`<C-]>`）
- `prev`: 切换到上一个建议（默认：`<C-[>`）
- `toggle`: 切换 NES 功能（默认：`<leader>cn`）

#### 过滤选项 (`filter`)

- `min_confidence`: 最小置信度阈值（默认：0.5）
- `max_suggestions_per_line`: 每行最大建议数（默认：1）
- `exclude_filetypes`: 排除的文件类型列表

## 使用方法

### 自动触发

当 `auto_trigger = true` 时，NES 会在您编辑代码时自动触发建议。

### 手动触发

使用配置的切换键（默认 `<leader>cn`）手动触发或关闭 NES 建议。

### 交互操作

- **接受建议**: 按 `<C-y>`（或您配置的键）接受当前显示的建议
- **拒绝建议**: 按 `<C-n>`（或您配置的键）拒绝当前建议
- **浏览建议**: 使用 `<C-]>` 和 `<C-[>`（或您配置的键）在多个建议之间切换

### API 调用

您也可以通过编程方式调用 NES 功能：

```lua
local nes = require("copilot.nes")

-- 请求建议
nes.request_suggestions()

-- 接受当前建议
nes.accept_current_suggestion()

-- 拒绝当前建议
nes.reject_current_suggestion()

-- 切换到下一个建议
nes.next_suggestion()

-- 切换到上一个建议
nes.prev_suggestion()

-- 切换 NES 功能
nes.toggle_nes()
```

## 显示效果

### 浮动窗口模式

当选择 `display.type = "float"` 时，NES 建议会以浮动窗口的形式显示，包含：

- 建议编号和总数
- 建议描述（如果有）
- 建议的具体代码更改
- 操作提示

### 内联高亮模式

当选择 `display.type = "inline"` 时，NES 会直接在代码中高亮显示建议的修改范围。

## 故障排除

### 检查配置

确保 NES 功能已启用：

```lua
:lua print(vim.inspect(require("copilot.config").next_edit_suggestions))
```

### 检查日志

启用详细日志以查看 NES 相关的调试信息：

```lua
require("copilot").setup({
  logger = {
    level = "trace",
  },
})
```

### 常见问题

1. **建议不显示**: 检查文件类型是否在排除列表中
2. **键盘映射冲突**: 检查配置的键盘映射是否与其他插件冲突
3. **性能问题**: 适当增加 `debounce` 时间或减少 `max_suggestions`

## 依赖要求

- Neovim 0.10.0 或更高版本
- Node.js v20 或更高版本
- GitHub Copilot Language Server 1.337.0 或更高版本
- 有效的 GitHub Copilot 订阅

## 示例配置

### 最小配置

```lua
require("copilot").setup({
  next_edit_suggestions = {
    enabled = true,
  },
})
```

### 完整配置

```lua
require("copilot").setup({
  next_edit_suggestions = {
    enabled = true,
    auto_trigger = true,
    debounce = 300,
    display = {
      type = "both",
      max_suggestions = 5,
      auto_show = true,
      timeout = 8000,
    },
    keymaps = {
      accept = "<Tab>",
      reject = "<S-Tab>",
      next = "<C-n>",
      prev = "<C-p>",
      toggle = "<leader>ct",
    },
    filter = {
      min_confidence = 0.7,
      max_suggestions_per_line = 2,
      exclude_filetypes = { 
        "help", "alpha", "dashboard", "NvimTree", 
        "Trouble", "lspinfo", "mason" 
      },
    },
  },
})
```

## 贡献

如果您发现了 bug 或有改进建议，请在 GitHub 仓库中提交 issue 或 pull request。

## 许可证

本集成遵循 copilot.lua 项目的许可证条款。