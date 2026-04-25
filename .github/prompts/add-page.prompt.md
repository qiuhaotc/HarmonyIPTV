---
description: "在 HarmonyOS 项目中添加一个新页面，包含路由注册和页面实现"
argument-hint: "页面名称及功能描述"
agent: "agent"
---

在 HarmonyOS 项目中添加一个新页面：

**页面名称/功能**: $input

步骤：
1. 在 `entry/src/main/ets/pages/` 创建页面文件（文件名用 PascalCase）
2. 使用 `@Entry` 和 `@Component` 装饰器
3. 实现页面布局和交互逻辑
4. 在 `entry/src/main/resources/base/profile/main_pages.json` 中注册页面路由

完成后运行编译命令验证：
```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
```
