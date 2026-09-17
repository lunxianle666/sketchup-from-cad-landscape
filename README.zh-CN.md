# sketchup-from-cad-landscape

[English](README.md)

用于景观 CAD → SketchUp 的 Codex 工作流 Skill，提供预检、原图保护、几何验证与失败恢复。已有本机实测记录，但每张新 DWG 都必须重新预检。

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

## 依赖与实测环境

需要支持 Skills 的 Codex、Windows、支持 COM 的 AutoCAD 桌面版、Python + pywin32、支持原生 DWG 导入的 SketchUp 桌面版，以及能查询实例/模型并提供授权 Ruby 执行的 SketchUp MCP 桥接。还需要已有的 AutoCAD 实体审计自动化 workflow/skill。

2026-09-17 本机实测使用 AutoCAD 2025、Python 3.12.10、SketchUp 2023 / 23.0.367、Ruby 2.7.2、Ringo-Sketchup-MCP 1.3.2 和 Codex CLI。环境包含本地 MCP Schema 兼容调整与进程级临时 Ruby 启用；不能把所有未修改的客户端组合称为已验证。其他版本可能兼容，但本仓库未验证。详情见 [Tested Environment](docs/TESTED_ENVIRONMENT.md)。

## 安装

先独立安装并验证外部工具，桥接安装遵循 [Ringo 官方仓库](https://github.com/Ringophilia/Ringo-Sketchup-MCP) 的说明，确认目标实例及授权 Ruby 能力。

当前 [OpenAI 官方说明](https://learn.chatgpt.com/docs/build-skills) 列出的用户级目录为 `~/.agents/skills`，项目级目录为 `.agents/skills`。下载或 clone 本仓库后，将完整项目文件夹放入其中，并命名为 `sketchup-from-cad-landscape`；不要覆盖已有 Skill。英文 README 提供有覆盖保护的 PowerShell 复制示例。

也可让 `$skill-installer` 从本仓库 GitHub 地址安装，注明 `SKILL.md` 位于仓库根目录。未出现时重启 Codex。历史本机安装使用 `~/.codex/skills`，这不是所有当前客户端通用的推荐路径。当前安装目录按官方文档核实，未在所有客户端重新实测。本次发布保持为独立 Skill，不额外制作插件包。

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

历史综合状态仍为 **PARTIAL**，包含极短边/注释导入丢失、模型重叠及待确认事项。本次整理未重跑这些测试，也未发布私人原始报告或测试图纸。精确数值和方法见 [匿名验证摘要](docs/TESTED_ENVIRONMENT.md)；仓库不附原测试夹具，不能据此直接复现全部历史测试。

原生导入会离散曲线，极短边可能丢失，部分注释无法保留；复杂 Spline 需要源参数与采样/重建，设计歧义需要人工确认。AutoCAD COM 面向 Windows。镜像/非均匀/动态/复杂嵌套块、任意曲线自交、全面面重叠检测、密集图案 Hatch 和其他软件版本未证明可靠。完整说明见 [Limitations](docs/LIMITATIONS.md)。

## 依赖与致谢

[Ringo-Sketchup-MCP](https://github.com/Ringophilia/Ringo-Sketchup-MCP) 是 Ringophilia 维护的第三方桥接，本仓库只引用，不分发其代码，不暗示官方合作关系。上游工具遵循各自许可证。

历史环境使用 `autocad-dwg-redraw`，但本地元数据未明确其来源和许可证，所以只描述为已有 AutoCAD 自动化 workflow/skill；不复制代码，不宣称作者关系。AutoCAD、SketchUp、Python/pywin32、SketchUp Ruby API 与 OpenAI Codex 均为独立依赖。

## 许可证

本仓库工作流和文档采用 [MIT License](LICENSE)。第三方依赖保持原有许可证；本仓库不包含第三方实现代码或大段第三方文档。
