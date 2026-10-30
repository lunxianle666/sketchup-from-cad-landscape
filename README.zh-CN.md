# sketchup-from-cad-landscape

[English](README.md)

用于景观 CAD → SketchUp 的 Codex 工作流 Skill，提供预检、原图保护、几何验证与失败恢复。已有本机实测记录，但每张新 DWG 都必须重新预检。

## 状态：冻结的历史独立组件

自 2026-10-30 起，本仓库冻结为仍可独立使用的历史指令型 Skill。后续维护集中到 [Landscape-Agent-Pack](https://github.com/lunxianle666/Landscape-Agent-Pack)，优先处理文档、兼容性与可复现缺陷。本次只添加文档冻结说明，GitHub 仓库 Archive 设置保持不变。

Landscape-Agent-Pack v0.2.0 已纳入本组件固定公开基线 [`cc28ffd4b9daea890fbe78fd3737c9669d042446`](https://github.com/lunxianle666/sketchup-from-cad-landscape/commit/cc28ffd4b9daea890fbe78fd3737c9669d042446) 的 Skill、必要运行文档及 LICENSE，并按 [基线报告](https://github.com/lunxianle666/Landscape-Agent-Pack/blob/v0.2.0/docs/SKILL_BASELINE_REPORT.md) 调整 Pack 内的来源措辞；不会在运行时跟随本仓库 main 更新。

新用户如需持续维护的规则/MCP、Python Core、QA 和 Bridge 入口，请从 [主项目正式版](https://github.com/lunxianle666/Landscape-Agent-Pack/releases/tag/v0.2.0) 与 [安装指南](https://github.com/lunxianle666/Landscape-Agent-Pack/blob/main/docs/INSTALL_WINDOWS.md) 开始。已有可用桌面自动化工具栈、只需历史工作流指令时，可继续选择本独立组件。避免重复安装同名 Skill；两种选择都不能省去插件依赖与 PRE-FLIGHT。

**版本说明：**截至 2026-10-30，本仓库没有远程 Tag 或 GitHub Release。旧教程与检测脚本横幅中的“v1.1”是上述基线提交的 Windows 安装/环境检测更新标识，不代表已打 Tag 或正式发行的 v1.1。本次冻结不补发 Release。引用精确快照请使用提交号；main ZIP 会包含后续文档。

## Windows 小白快速安装

**历史 Windows 安装/环境检测（“v1.1”为更新标识，并非发行版本）。没有 Git 也能安装。** 以下步骤保留给选择上述独立 Skill 的用户。

1. 在 GitHub 点击 **Code → Download ZIP**，或[直接下载 ZIP](https://github.com/lunxianle666/sketchup-from-cad-landscape/archive/refs/heads/main.zip)。
2. 完整解压，进入包含 `install.ps1` 的文件夹。
3. 在这个文件夹打开 PowerShell，运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```
4. 安装后会自动检测环境；补齐依赖后可再次运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check-environment.ps1
   ```
5. 按 **Missing / Action Required** 补齐条件，再在 Codex 中调用 Skill。

无需管理员权限，也不会永久修改执行策略。**Skill 安装成功不代表完整自动化已就绪。** 安装器只复制 Skill 与它引用的两份运行参考文档；已有不同版本会先完整备份到 Skills 扫描目录之外。

不会 PowerShell？请看[中文小白快速开始](docs/QUICK_START.zh-CN.md)。英文问题说明见 [Troubleshooting](docs/TROUBLESHOOTING.md)。

## 项目用途

本项目是一套指令型 Skill，编排已有 AutoCAD 自动化和 SketchUp MCP 能力。它不是 AutoCAD 插件、SketchUp MCP 服务器或几何内核；安装 Skill 不会自动安装这些外部工具。完整操作规则见 [SKILL.md](SKILL.md)。

CAD 导入可能保留顶点却离散曲线，也可能丢失极短边和注释。Skill 将这些问题纳入验收，保护原始图纸，并把无法确定的设计意图交给人工确认。

## 核心能力与流程

- PRE-FLIGHT 输出 `READY`、`READY_WITH_REVIEW` 或 `BLOCKED`。
- RAW 只读保护；所有清图只在独立 CLEAN 副本进行。
- 审计实体、图层、源曲线参数和 Block 变换，区分 `SAFE_AUTO_FIX`、`REVIEW_REQUIRED`、`INVALID`。
- 遇到多个合理解释执行 `STOP GUESSING`：保留或隔离对象，合并询问，继续其他确定部分。
- 原生 DWG 导入，保留独立 `CAD_REFERENCE`；CAD 是 XY 几何的唯一依据。
- 只在 MODEL 中按真实 CAD 参数自适应细化曲线；保留原生参考结果。
- Block 转可复用组件，组织 Group / Component / Tags，检查模型健康与几何一致性。
- 保存检查点，失败后局部恢复；最终实际重开文件并比较结构和关键几何。

流程图见英文 [Workflow](README.md#workflow)：DWG → PRE-FLIGHT → CAD AUDIT → 安全修复/隔离待确认 → CLEAN → 原生导入 → CAD_REFERENCE → 确定部分三维化 → 曲线检查 → 组件与标签组织 → 几何验收 → 保存 → 重开。

## 两个依赖等级

**Level 1：安装 Skill。** 只需 Windows 和支持 Skills 的 Codex。没有 CAD、SU、Python、MCP 或 Git 也能安装文件。

**Level 2：完整 CAD → SU 自动化。** 需要下表依赖，并在实际项目上完成 PRE-FLIGHT。

| 组件 | 安装 Skill | 完整自动化 |
| --- | --- | --- |
| Windows + Codex Skills | 必需 | 必需 |
| Git | 可选 | 可选 |
| AutoCAD 桌面版 / COM | 不需要 | 必需 |
| Python | 不需要 | 必需 |
| pywin32 | 不需要 | 必需 |
| SketchUp 桌面版 / DWG importer | 不需要 | 必需 |
| 兼容 SketchUp MCP 桥接 | 不需要 | 必需 |
| AutoCAD 源实体审计 workflow | 不需要 | 必需 |

## 依赖与实测环境

需要支持 Skills 的 Codex、Windows、支持 COM 的 AutoCAD 桌面版、Python + pywin32、支持原生 DWG 导入的 SketchUp 桌面版，以及能查询实例/模型并提供授权 Ruby 执行的 SketchUp MCP 桥接。还需要已有的 AutoCAD 实体审计自动化 workflow/skill。

2026-09-17 本机实测使用 AutoCAD 2025、Python 3.12.10、SketchUp 2023 / 23.0.367、Ruby 2.7.2、Ringo-Sketchup-MCP 1.3.2 和 Codex CLI。环境包含本地 MCP Schema 兼容调整与进程级临时 Ruby 启用；不能把所有未修改的客户端组合称为已验证。其他版本可能兼容，但本仓库未验证。详情见 [Tested Environment](docs/TESTED_ENVIRONMENT.md)。

## 安装方式与安装器行为

**方式 A：Download ZIP（推荐）。** 按前面的快速安装步骤操作，Git 不是必需条件。必须完整解压后运行，不能只下载 `install.ps1`。

**方式 B：Git clone（开发者）。** 已安装 Git 时才使用：

```powershell
git clone https://github.com/lunxianle666/sketchup-from-cad-landscape.git
cd sketchup-from-cad-landscape
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

默认安装到 `~/.agents/skills/sketchup-from-cad-landscape`，这是当前 [OpenAI 官方说明](https://learn.chatgpt.com/docs/build-skills) 的用户级目录。可通过 `-SkillsDirectory .\.agents\skills` 指定项目级目录；检测脚本使用同一参数检查指定位置。

安装器默认不触碰历史 `~/.codex/skills`。已有正常工作的旧目录版本时，先在 Codex 确认发现情况，避免装出重复 Skill。自定义目标意味着你明确选择更新那个位置。

相同内容不重复安装；不同内容会连同自定义文件一起完整备份到 Skills 目录旁的 `skill-install-backups`，名称包含时间与唯一标识，随后安装公开运行文件并显示备份位置。链接目标会拒绝自动更新；替换失败时尝试恢复原目录，不删除原文件。

只安装 `SKILL.md` 和它明确引用的 `docs/TESTED_ENVIRONMENT.md`、`docs/LIMITATIONS.md`，不会复制 README、安装器或其他无关文档。保留下载包，方便以后运行检测。可加 `-SkipEnvironmentCheck` 只安装文件；安装后的文件存在不等于 Codex 已实际发现。

环境检测不启动 CAD/SU、不实例化 COM、不装软件、不修改第三方设置。它能检查软件线索、COM 注册、Python 与 pywin32，但不能代替授权 MCP、Ruby、目标实例和实际 DWG 导入的 PRE-FLIGHT。完整状态为 `UNKNOWN` 时，请继续做实际预检，不能理解为已就绪。详见[小白教程](docs/QUICK_START.zh-CN.md)与[常见问题](docs/TROUBLESHOOTING.md)。

## 使用

提供 DWG、输出目录、建模范围、单位及权威标高/厚度等参数：

```text
$sketchup-from-cad-landscape 根据这个 DWG 建立景观 SU 基础模型。先预检，缺失设计参数合并询问，保留原图，最终保存并重开验证。
```

可按目标补充：

- 基础总平：建立已确认的道路、铺装和水体，保留 CAD_REFERENCE，汇总未闭合边界。
- 建筑与墙：按提供的高度表建模，先确认墙中心线/边线含义，再派生墙体边界。
- 曲线景观：关键硬质曲线控制在 0.5 mm，普通曲线 1.0 mm；只根据 CAD 原始参数细化 MODEL，并说明采样范围。
- 植物块：转轻量可复用组件，保留插入点、旋转和比例；疑似重复种植保留待确认。

XY 来自实际 CAD 实体。高度按 CAD 标高、剖立面、设计说明、用户参数及已确认规则依次读取；存在冲突或关键缺失时不能猜测。

## 数据保护与精度目标

记录 RAW 路径、大小、修改时间及可行时 SHA-256，最终复核原图未变。保护未保存文档和已有输出；只在 CLEAN 修复有证据的对象。MCP 写入超时后先检查实际执行状态，避免重复操作。仓库不提供上传器，但 Codex 和外部工具如何处理数据取决于各自配置与政策。

| 验收项 | 默认目标 |
| --- | --- |
| 线性定位 | ≤ 0.1 mm |
| 关键硬质景观曲线 | ≤ 0.5 mm |
| 普通景观曲线 | ≤ 1.0 mm |
| 面积 | ≤ 0.1% PASS；> 0.1% 且 ≤ 0.5% WARNING；> 0.5% REVIEW/FAIL |

这些是工作流验收目标，不是任何输入的无条件保证；用户更严要求优先。面积同时报告绝对 mm² 差值。顶点或外接框一致不证明连续曲线一致；采样偏差不是数学认证的全局误差上界。

## 实测结果与限制

匿名化 **30 项合成景观 CAD 压力测试**形成 22 个区域 Group、19 个 MODEL 植物/小品组件实例。最大线性定位误差约 `4.66e-10 mm`，原生曲线抽样偏差约 `8.458 mm`，按源 CAD 参数细化 MODEL 后约 `0.199 mm`，最大面积误差约 `0.0351%`，保存重开通过。

历史综合状态仍为 **PARTIAL**，包含极短边/注释导入丢失、模型重叠及待确认事项。打包及本次冻结均未重跑这些测试，也未公开私人原始报告、CAD 夹具及对应截图/演示。精确数值和方法见 [匿名验证摘要](docs/TESTED_ENVIRONMENT.md)；不能从本仓库直接复现全部历史测试。主项目后续验收不会升级本组件的历史结论。

原生导入会离散曲线，极短边可能丢失，部分注释无法保留；复杂 Spline 需要源参数与采样/重建，设计歧义需要人工确认。AutoCAD COM 面向 Windows。镜像/非均匀/动态/复杂嵌套块、任意曲线自交、全面面重叠检测、密集图案 Hatch 和其他软件版本未证明可靠。完整说明见 [Limitations](docs/LIMITATIONS.md)。

## 依赖与致谢

[Ringo-Sketchup-MCP](https://github.com/Ringophilia/Ringo-Sketchup-MCP) 是 Ringophilia 维护的第三方桥接，本仓库只引用，不分发其代码，不暗示官方合作关系。上游工具遵循各自许可证。

历史环境使用 `autocad-dwg-redraw`，但本地元数据未明确其来源和许可证，所以只描述为已有 AutoCAD 自动化 workflow/skill；不复制代码，不宣称作者关系。AutoCAD、SketchUp、Python/pywin32、SketchUp Ruby API 与 OpenAI Codex 均为独立依赖。

## 许可证

本仓库工作流和文档采用 [MIT License](LICENSE)。第三方依赖保持原有许可证；本仓库不包含第三方实现代码或大段第三方文档。
