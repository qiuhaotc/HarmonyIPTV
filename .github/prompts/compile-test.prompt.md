---
description: "运行 HarmonyOS 项目编译命令，验证代码是否可以成功编译"
argument-hint: "可选：说明本次编译验证的目的"
agent: "agent"
---

运行以下 HarmonyOS 项目编译命令，验证代码是否可以成功编译：

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" clean --mode module -p product=default -p buildMode=release assembleHap --analyze=normal --parallel --incremental --daemon
```

编译完成后：
1. 如果编译成功，报告成功信息
2. 如果编译失败，分析错误信息并提供修复建议
