# Windows quick start (v1.1)

[简体中文](QUICK_START.zh-CN.md) · [Home](../README.md)

## 1. What this does

A workflow Skill that helps Codex turn landscape CAD plans into SketchUp base models with source protection, checkpoints and measured validation. It does not install the desktop automation stack.

## 2. Download without Git

Open [the repository](https://github.com/lunxianle666/sketchup-from-cad-landscape), choose **Code -> Download ZIP**, or [download the ZIP directly](https://github.com/lunxianle666/sketchup-from-cad-landscape/archive/refs/heads/main.zip). Right-click the ZIP, select **Extract All**, then enter the folder containing `install.ps1` and `SKILL.md`. Do not run inside the ZIP preview. **No Git required.**

## 3. Install the Skill

Use Windows and Codex with Skills support. CAD, SketchUp, Python and MCP are not required for file installation. Double-clicking `.ps1` may open an editor instead of running it.

In File Explorer's address bar inside the extracted folder, type `powershell` and press Enter. In that window run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

No administrator permissions are needed. Bypass applies only to this new process, not permanent system policy; managed policy may still block it. Success prints `SKILL INSTALLED` and the target. The default is `~/.agents/skills/sketchup-from-cad-landscape`. Identical installations are unchanged; different installations, including custom files, are preserved in a timestamped backup outside discovery. Only SKILL.md and its two referenced runtime documents are installed.

If an existing legacy installation already works, confirm discovery before installing a second copy.

## 4. Check the environment

The installer runs the checker automatically. Rerun it from the extracted folder after configuring dependencies:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check-environment.ps1
```

It installs nothing and changes no applications, registry, plugin, MCP or firewall settings. Custom installs can require manual confirmation.

## 5. Understand the output

- **PASS:** the specific bounded check passed.
- **WARN:** evidence found, but attention or confirmation needed.
- **FAIL:** a checked requirement failed; follow the action listed.
- **UNKNOWN:** the detector cannot reliably establish the state; not proof of absence.

**Skill Installation: READY / NOT_INSTALLED** means file presence, not actual client discovery. **Full CAD -> SketchUp Automation: NOT_READY / UNKNOWN** distinguishes missing checked requirements from unverified live capabilities. This checker does not report full READY without actual authenticated MCP, Ruby authorization, target-instance and importer pre-flight.

Follow **Missing / Action Required**. Remove local paths/account names before sharing results; never send credentials or private drawings.

## 6. Two levels

Skill installation only provides workflow instructions. Full automation additionally needs AutoCAD desktop/COM, Python/pywin32, SketchUp desktop with native DWG import, a compatible SketchUp MCP bridge with authorized Ruby execution, and a source-entity audit workflow. Git remains optional.

The tested third-party bridge was [Ringo-Sketchup-MCP](https://github.com/Ringophilia/Ringo-Sketchup-MCP) 1.3.2. Follow upstream setup. Other bridges are not automatically compatible.

## 7. First use

Refresh/restart Codex if necessary. Identify the DWG, output folder, scope and authoritative heights/thicknesses, then send:

```text
$sketchup-from-cad-landscape Build a SketchUp base model from this landscape DWG. Run pre-flight first, preserve the original DWG, group missing parameters into one review request, and save/reopen the final model for validation.
```

Do not skip source-specific PRE-FLIGHT even when dependency discovery passes.

## 8. Common problems

Git missing? Use ZIP. PowerShell blocked? Use the process-only command above. Skill undiscovered? Check the printed directory and client support, refresh/restart, and avoid duplicate legacy/current copies. AutoCAD COM, Python, pywin32, SketchUp, or MCP problems? Follow [Troubleshooting](TROUBLESHOOTING.md), which includes official dependency sources and backup restoration.
