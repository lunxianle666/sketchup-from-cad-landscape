# Windows 小白快速开始（v1.1）

[English](QUICK_START.md) · [返回首页](../README.zh-CN.md)

## 1. 这个项目能干什么

让 Codex 按有原图保护、检查点和几何验收的流程，把景观 CAD 总平转成 SketchUp 基础模型。它是一套工作指令，不是 CAD/SU 软件本身。

## 2. 最简单下载方法：不需要 Git

打开[项目页面](https://github.com/lunxianle666/sketchup-from-cad-landscape)，点击绿色 **Code** 按钮，再点 **Download ZIP**。也可以[直接下载 ZIP](https://github.com/lunxianle666/sketchup-from-cad-landscape/archive/refs/heads/main.zip)。

找到下载的 ZIP，右键选择“全部提取”，解压到你方便找到的文件夹。进入解压后的 `sketchup-from-cad-landscape-main`，看到 `install.ps1` 和 `SKILL.md` 才是正确位置。不要在压缩包预览窗口里运行脚本。

## 3. 安装 Skill

先安装并打开支持 Skills 的 Codex。安装 Skill 本身不要求 AutoCAD、SketchUp、Python、MCP 或 Git。

双击 `.ps1` 可能只打开编辑器。可靠方法：在上述文件夹的文件资源管理器地址栏输入 `powershell`，按 Enter，打开的窗口就位于这个文件夹。复制下面一行，按 Enter：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

不要选择“以管理员身份运行”。这行命令只对新启动的 PowerShell 进程临时使用 Bypass，不会永久修改系统执行策略；企业策略可能仍然阻止执行，届时请联系管理员，不要强制更改。

成功时会看到 `SKILL INSTALLED` 和目标路径。默认是你自己的用户目录下 `.agents\skills\sketchup-from-cad-landscape`。原有相同版本会显示 `already installed`；不同版本会先完整备份，并告诉你备份位置。安装文件只有 Skill 与它引用的两份运行参考文档。

已有旧目录 Skill 正常工作时，不必再装第二份；先在 Codex 确认。不要随意指定不熟悉的安装目标。

## 4. 环境检测

安装后会自动运行检测。以后补齐依赖后，在同一下载文件夹再次运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check-environment.ps1
```

脚本只检查，不会自动安装 CAD、SU、Python、Ringo，也不会修改插件、注册表、MCP 配置或防火墙。软件使用自定义安装路径时，部分结果可能是 UNKNOWN。

## 5. 怎样看结果

| 标记 | 含义 |
| --- | --- |
| PASS | 这一项在检查范围内通过，例如软件文件存在或 Python 可运行 |
| WARN | 有线索但有注意事项，例如旧目录安装或桥接运行状态未确认 |
| FAIL | 检查失败，按下一步说明补齐，例如 Python/pywin32 不可用 |
| UNKNOWN | 当前方法无法可靠判断，不代表软件一定没安装 |

重点看底部两项：

- **Skill Installation: READY / NOT_INSTALLED**：是否找到 Skill 文件。READY 仍需要在 Codex 中确认能发现它。
- **Full CAD -> SketchUp Automation: NOT_READY / UNKNOWN**：缺少已检测的必需项则 NOT_READY；基础项存在但运行能力没验收则 UNKNOWN。完整 READY 必须通过 Codex 的实际 PRE-FLIGHT，这个只读脚本不会凭安装线索报 READY。

按 **Missing / Action Required** 逐项处理。把结果发给协助者前，删掉本机路径/账户名；不要发 token、密码或私人图纸。

## 6. 安装成功与完整自动化的区别

安装成功表示 Codex 有了这套工作指令。真正运行还需要支持 COM 的 AutoCAD 桌面版、Python + pywin32、带原生 DWG 导入能力的 SketchUp 桌面版、能授权 Ruby 的兼容 MCP 桥接，以及源实体审计能力。Git 始终不是必需条件。

Ringo 是[第三方项目](https://github.com/Ringophilia/Ringo-Sketchup-MCP)，本项目历史测试使用 1.3.2。按上游官方说明配置，不要因为 SketchUp 已安装就认为 MCP 已连通，也不能假定其他桥接必然兼容。

## 7. 第一次使用

刷新或重启 Codex，找到 `sketchup-from-cad-landscape`。提供 DWG、输出目录、建模范围和明确的标高/厚度参数，再发送：

```text
$sketchup-from-cad-landscape 根据这个 DWG 建立景观 SU 基础模型。先预检，缺失设计参数合并询问，保留原图，最终保存并重开验证。
```

第一次先让 Agent 检查环境和图纸，不要直接要求跳过预检完成全量建模。缺少软件时可以先咨询如何补齐依赖。

## 8. 常见问题

- **git not found**：不用装 Git，按 Download ZIP 方法即可。
- **PowerShell blocked**：使用上面仅当前进程生效的命令，不修改 LocalMachine 策略。
- **Codex 找不到 Skill**：检查安装输出的路径和 `SKILL.md`，刷新/重启 Codex，确认客户端支持该目录；避免旧目录与新目录重复安装。
- **AutoCAD COM unavailable**：检查是否为支持 COM 的桌面版、COM 注册及进程权限；检查器不会替你启动 CAD 或修复注册。
- **Python missing**：从 [python.org](https://www.python.org/downloads/windows/) 安装或把已有 Python 加入 PATH；WindowsApps 占位命令不算可用 Python。
- **pywin32 missing**：按检测结果选定的 Python 安装 `pywin32`，避免装到另一个解释器。详情见[故障排查](TROUBLESHOOTING.md#pywin32-missing)。
- **SketchUp missing**：确认是支持 DWG 导入的桌面版；网页/iPad 版不满足此流程。
- **MCP missing/not running**：按 Ringo 官方说明配置并启动，然后在 Codex 检查 `bridge_status` 和 `model_get_info`。UNKNOWN 时先确认，不要直接重装一切。

更多原因、安装目标和备份恢复方法见 [Troubleshooting](TROUBLESHOOTING.md)。
