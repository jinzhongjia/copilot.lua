# LSP 扩展方式研究发现

## Neovim LSP 自定义处理器机制

### 官方文档要点
1. **vim.lsp.config()**: 用于定义 LSP 客户端配置
2. **LspAttach 事件**: 在 LSP 客户端附加到缓冲区时触发
3. **自定义处理器**: 可以通过 handlers 参数添加自定义消息处理器
4. **客户端能力检查**: 使用 `client:supports_method()` 检查服务器能力

### 自定义处理器实现方式

基于 GitHub Issue #14258 的发现，有两种主要方式实现自定义 LSP 处理器：

#### 方式一：标准 handlers 配置
```lua
lspconfig.server_name.setup {
  handlers = {
    ["custom/method"] = function(err, result, ctx, config)
      -- 处理自定义消息
    end
  }
}
```

#### 方式二：客户端请求拦截（高级用法）
```lua
local function resolve_handler(client, method)
  return client.handlers[method] or vim.lsp.handlers[method]
end

local function client_request_override(client)
  local original_request = client.request
  return function(method, params, handler, bufnr)
    if type(handler) == 'table' and handler.type == 'local_lsp' then
      handler.handler(method, params, client.id, bufnr)
      return true, 1
    else
      return original_request(method, params, handler, bufnr)
    end
  end
end
```

## Next Edit Suggestions 集成策略

### 核心集成点

#### 1. LSP 消息处理扩展
需要在 copilot.lua 的 LSP 层添加对以下消息的处理：
- `textDocument/publishNextEditSuggestions` (通知)
- `github.copilot.didAcceptNextEditSuggestionItem` (命令)
- `github.copilot.didRejectNextEditSuggestionItem` (命令)

#### 2. 事件监听机制
- 监听 `textDocument/didChange` 事件触发 NES 请求
- 处理服务器发送的 NES 通知
- 管理 NES 建议的生命周期

#### 3. 用户界面集成
- 设计 NES 建议的显示方式（区别于内联建议）
- 添加接受/拒绝 NES 的键盘映射
- 实现 NES 建议的高亮显示

#### 4. 配置系统扩展
- 添加 NES 相关配置选项
- 支持启用/禁用 NES 功能
- 配置 NES 的触发条件和显示样式

### 技术实现路径

#### 阶段一：LSP 协议扩展
1. 在 `lua/copilot/lsp/init.lua` 中添加 NES 相关的处理器
2. 扩展 `get_execute_command()` 函数支持 NES 命令
3. 添加对 `textDocument/publishNextEditSuggestions` 通知的处理

#### 阶段二：NES 管理模块
1. 创建 `lua/copilot/nes/` 目录
2. 实现 NES 建议的存储和管理
3. 处理 NES 建议的显示逻辑

#### 阶段三：用户界面集成
1. 在 `lua/copilot/suggestion/` 中集成 NES 显示
2. 添加 NES 相关的键盘映射
3. 实现 NES 建议的接受/拒绝逻辑

#### 阶段四：配置和文档
1. 扩展配置系统支持 NES 选项
2. 添加 NES 相关的命令和 API
3. 编写使用文档和示例

### 关键技术挑战

1. **消息路由**: 如何正确路由 NES 相关的 LSP 消息
2. **状态管理**: 如何管理多个 NES 建议的状态
3. **UI 集成**: 如何在现有的建议系统中集成 NES 显示
4. **性能优化**: 如何避免 NES 影响现有功能的性能
5. **兼容性**: 如何确保与现有配置和插件的兼容性

