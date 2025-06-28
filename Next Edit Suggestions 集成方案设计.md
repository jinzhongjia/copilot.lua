# Next Edit Suggestions 集成方案设计

## 1. 总体架构设计

### 1.1 集成架构图
```
┌─────────────────────────────────────────────────────────────┐
│                    copilot.lua 插件                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   suggestion/   │  │      nes/       │  │      lsp/       │ │
│  │   (现有建议)     │  │  (NES 新模块)    │  │   (LSP 集成)     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      api/ (统一 API 层)                       │
├─────────────────────────────────────────────────────────────┤
│                   config/ (配置管理)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Copilot Language Server                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Inline Completion│  │ Next Edit Sugg. │  │ Panel Completion│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 模块职责划分

#### 1.2.1 NES 核心模块 (`lua/copilot/nes/`)
- **init.lua**: NES 主模块，管理 NES 的生命周期
- **manager.lua**: NES 建议管理器，处理建议的存储和状态
- **display.lua**: NES 显示逻辑，处理建议的可视化
- **handlers.lua**: NES 事件处理器，处理用户交互

#### 1.2.2 LSP 扩展 (`lua/copilot/lsp/`)
- 扩展现有的 `init.lua`，添加 NES 相关的 LSP 处理器
- 添加对 `textDocument/publishNextEditSuggestions` 通知的处理
- 扩展命令执行器支持 NES 相关命令

#### 1.2.3 API 扩展 (`lua/copilot/api/`)
- 添加 NES 相关的 API 接口
- 提供统一的 NES 操作方法

#### 1.2.4 配置扩展 (`lua/copilot/config/`)
- 添加 NES 相关的配置选项
- 支持 NES 功能的启用/禁用

## 2. 详细设计规范

### 2.1 NES 数据结构设计

#### 2.1.1 NES 建议对象
```lua
local nes_suggestion = {
  id = "unique_suggestion_id",
  type = "next_edit_suggestion",
  range = {
    start = { line = 10, character = 5 },
    ["end"] = { line = 10, character = 15 }
  },
  new_text = "suggested replacement text",
  description = "Fix variable name typo",
  confidence = 0.85,
  created_at = os.time(),
  status = "pending" -- pending, accepted, rejected, expired
}
```

#### 2.1.2 NES 管理器状态
```lua
local nes_manager = {
  suggestions = {}, -- 当前活跃的建议列表
  current_suggestion = nil, -- 当前显示的建议
  config = {}, -- NES 配置
  client_id = nil, -- LSP 客户端 ID
  buffer_id = nil, -- 当前缓冲区 ID
  last_change_time = 0, -- 最后修改时间
  debounce_timer = nil -- 防抖定时器
}
```

### 2.2 LSP 协议扩展设计

#### 2.2.1 消息处理器注册
```lua
-- 在 lsp/init.lua 中添加
local nes_handlers = {
  ["textDocument/publishNextEditSuggestions"] = function(err, result, ctx, config)
    require("copilot.nes").handle_suggestions(result, ctx.client_id, ctx.bufnr)
  end,
  
  ["github.copilot.didAcceptNextEditSuggestionItem"] = function(err, result, ctx, config)
    require("copilot.nes").handle_accept_response(result, ctx.client_id)
  end,
  
  ["github.copilot.didRejectNextEditSuggestionItem"] = function(err, result, ctx, config)
    require("copilot.nes").handle_reject_response(result, ctx.client_id)
  end
}

-- 扩展现有的 setup 函数
function M.setup(server_config, copilot_node_command)
  -- 现有代码...
  
  -- 添加 NES 处理器
  if server_config.handlers then
    vim.tbl_extend("force", server_config.handlers, nes_handlers)
  else
    server_config.handlers = nes_handlers
  end
  
  -- 现有代码...
end
```

#### 2.2.2 命令执行扩展
```lua
-- 扩展 get_execute_command 函数
function M.get_execute_command()
  local commands = {
    -- 现有命令...
    "github.copilot.didAcceptNextEditSuggestionItem",
    "github.copilot.didRejectNextEditSuggestionItem",
  }
  return commands
end
```

### 2.3 NES 显示系统设计

#### 2.3.1 显示策略
1. **浮动窗口显示**: 使用 Neovim 的浮动窗口显示 NES 建议
2. **内联高亮**: 在原文本上使用高亮显示建议的修改范围
3. **状态栏提示**: 在状态栏显示 NES 建议的数量和状态

#### 2.3.2 显示组件设计
```lua
local display = {
  -- 浮动窗口配置
  float_win = {
    width = 60,
    height = 10,
    border = "rounded",
    style = "minimal"
  },
  
  -- 高亮组配置
  highlight_groups = {
    CopilotNESRange = { bg = "#3e4451", fg = "#abb2bf" },
    CopilotNESText = { bg = "#2c313c", fg = "#98c379" },
    CopilotNESBorder = { fg = "#61afef" }
  },
  
  -- 显示函数
  show_suggestion = function(suggestion) end,
  hide_suggestion = function() end,
  update_suggestion = function(suggestion) end
}
```

### 2.4 事件处理系统设计

#### 2.4.1 事件监听器
```lua
local event_handlers = {
  -- 文档变化事件
  on_text_changed = function(bufnr)
    local nes = require("copilot.nes")
    nes.request_suggestions(bufnr)
  end,
  
  -- 光标移动事件
  on_cursor_moved = function(bufnr)
    local nes = require("copilot.nes")
    nes.update_current_suggestion(bufnr)
  end,
  
  -- 缓冲区离开事件
  on_buf_leave = function(bufnr)
    local nes = require("copilot.nes")
    nes.clear_suggestions(bufnr)
  end
}
```

#### 2.4.2 键盘映射设计
```lua
local keymaps = {
  -- 接受当前 NES 建议
  accept_nes = {
    mode = "n",
    key = "<C-y>",
    action = function()
      require("copilot.nes").accept_current_suggestion()
    end,
    desc = "Accept Next Edit Suggestion"
  },
  
  -- 拒绝当前 NES 建议
  reject_nes = {
    mode = "n", 
    key = "<C-n>",
    action = function()
      require("copilot.nes").reject_current_suggestion()
    end,
    desc = "Reject Next Edit Suggestion"
  },
  
  -- 切换到下一个 NES 建议
  next_nes = {
    mode = "n",
    key = "<C-]>",
    action = function()
      require("copilot.nes").next_suggestion()
    end,
    desc = "Next Edit Suggestion"
  },
  
  -- 切换到上一个 NES 建议
  prev_nes = {
    mode = "n",
    key = "<C-[>",
    action = function()
      require("copilot.nes").prev_suggestion()
    end,
    desc = "Previous Edit Suggestion"
  }
}
```

### 2.5 配置系统设计

#### 2.5.1 NES 配置选项
```lua
local default_nes_config = {
  -- 启用 NES 功能
  enabled = true,
  
  -- 自动触发设置
  auto_trigger = true,
  debounce = 500, -- 防抖延迟 (毫秒)
  
  -- 显示设置
  display = {
    type = "float", -- "float", "inline", "both"
    max_suggestions = 3,
    auto_show = true,
    timeout = 5000 -- 建议超时时间 (毫秒)
  },
  
  -- 键盘映射设置
  keymaps = {
    accept = "<C-y>",
    reject = "<C-n>",
    next = "<C-]>",
    prev = "<C-[>",
    toggle = "<leader>cn"
  },
  
  -- 过滤设置
  filter = {
    min_confidence = 0.5,
    max_suggestions_per_line = 1,
    exclude_filetypes = { "help", "alpha", "dashboard" }
  }
}
```

#### 2.5.2 配置集成
```lua
-- 在主配置中集成 NES 配置
local copilot_config = {
  -- 现有配置...
  
  -- 新增 NES 配置
  next_edit_suggestions = default_nes_config,
  
  -- 现有配置...
}
```

## 3. 实现优先级和里程碑

### 3.1 第一阶段：基础架构 (MVP)
- [ ] 创建 NES 模块基础结构
- [ ] 实现基本的 LSP 消息处理
- [ ] 添加简单的 NES 建议显示
- [ ] 实现基本的接受/拒绝功能

### 3.2 第二阶段：功能完善
- [ ] 完善 NES 建议管理器
- [ ] 实现浮动窗口显示
- [ ] 添加键盘映射和用户交互
- [ ] 实现配置系统集成

### 3.3 第三阶段：优化和扩展
- [ ] 性能优化和防抖处理
- [ ] 添加高级显示选项
- [ ] 实现建议过滤和排序
- [ ] 添加详细的错误处理

### 3.4 第四阶段：文档和测试
- [ ] 编写使用文档
- [ ] 添加配置示例
- [ ] 实现单元测试
- [ ] 性能测试和优化

## 4. 兼容性考虑

### 4.1 向后兼容性
- 确保 NES 功能不影响现有的内联建议功能
- 保持现有 API 的兼容性
- 支持渐进式启用 NES 功能

### 4.2 配置兼容性
- NES 配置作为可选配置添加
- 默认情况下 NES 功能可以禁用
- 支持细粒度的功能控制

### 4.3 性能考虑
- 使用防抖机制避免频繁请求
- 实现建议缓存机制
- 优化显示更新逻辑
- 支持异步处理

