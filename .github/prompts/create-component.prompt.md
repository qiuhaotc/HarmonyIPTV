---
description: "创建一个新的 HarmonyOS 自定义组件，包含装饰器、状态管理和 UI 布局"
argument-hint: "组件名称及功能描述"
agent: "agent"
---

在 `entry/src/main/ets/` 合适的目录下创建一个新的 HarmonyOS 自定义组件：

**组件名称/功能**: $input

要求：
- 使用 `@Component` 装饰器
- 实现 `build()` 方法和完整的 UI 布局
- 合理使用 `@State`、`@Prop`、`@Link` 等状态管理装饰器
- 符合 HarmonyOS 声明式 UI 规范
- 保持代码简洁可读

创建完成后，运行编译命令验证：
```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
```
