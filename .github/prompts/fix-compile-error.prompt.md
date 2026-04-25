---
description: "分析并修复 HarmonyOS 项目编译错误"
argument-hint: "粘贴编译错误信息（可选，不填则先运行编译获取错误）"
agent: "agent"
---

修复 HarmonyOS 项目的编译错误：

$input

处理流程：
1. 如果没有提供错误信息，先运行编译命令获取：
   ```powershell
   & "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
   ```
2. 分析错误信息，定位问题代码文件和行号
3. 查阅 HarmonyOS 文档确认正确用法
4. 修正代码
5. 重新运行编译命令验证修复结果
6. 如果仍有错误，重复步骤 2-5 直到编译通过
