# Installation and environment troubleshooting

[English quick start](QUICK_START.md) · [中文小白教程](QUICK_START.zh-CN.md)

## Git is not recognized

Git is optional. Use **Code -> Download ZIP**, extract the complete package and run `install.ps1` from that folder. Neither installer nor checker invokes Git.

## PowerShell script cannot run

Open PowerShell in the extracted folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check-environment.ps1
```

This applies to each new process only. Do not change LocalMachine policy or use administrator mode for Skill installation. Organization policy can override it; ask your administrator rather than bypassing managed controls. Use the reviewed scripts from the official repository, not arbitrary downloads.

## Skill not discovered

Confirm that the printed target contains `SKILL.md`; the default is `~/.agents/skills/sketchup-from-cad-landscape` per [OpenAI documentation](https://learn.chatgpt.com/docs/build-skills). Refresh/restart Codex and check Skills support. Historical `~/.codex/skills` discovery varies by client. Avoid duplicate copies of the same Skill name.

To select a repository-level target, use `-SkillsDirectory .\.agents\skills` on both scripts. This selects that directory exactly. It does not automatically install external dependencies or prove Codex discovery.

## Existing Skill and backup restoration

Identical runtime files are left alone. Different content, including extra user files, is moved intact to `skill-install-backups` beside the selected Skills directory, with timestamp and unique suffix. Backups are outside the selected discovery directory so they do not appear as duplicate Skills. Linked paths are refused rather than followed.

To restore, close active work using that Skill, move the newly installed folder somewhere safe, then copy the complete printed backup folder to the original target. Do not copy backups into Skills under extra names, delete the only copy, or overwrite unrelated files. If installation fails after staging, preserve any reported staging/failed folders and inspect the message. Replacement failures attempt rollback without deletion.

## AutoCAD COM unavailable

Use a licensed AutoCAD desktop version with COM support. Check versioned ProgIDs and process permissions; an elevated AutoCAD instance may need matching automation permissions. Registry discovery only confirms a resolvable ProgID, not a working document connection. The checker never creates a COM instance or starts AutoCAD. Do actual safe connection checks through PRE-FLIGHT. [Autodesk support](https://www.autodesk.com/support) covers product installation/repair.

## Python missing

The checker tries `python`, `python3`, `py -3`, registered Python installs and common per-user installs. It skips WindowsApps launcher placeholders. Install from [Python's official Windows downloads](https://www.python.org/downloads/windows/) or expose an existing interpreter on PATH. It will not install Python for you. A custom unregistered interpreter might not be detected.

## pywin32 missing

The check actually imports `win32com.client` using the selected interpreter, preferring a discovered interpreter where that import succeeds. Install into the same interpreter printed by the checker, not a different Python. The following example requires a working `python` command pointing to that interpreter:

```powershell
python -m pip install pywin32
```

With a custom path, use PowerShell's call operator: `& '<python executable>' -m pip install pywin32`. See the [pywin32 project](https://github.com/mhammond/pywin32). Scripts never run pip automatically.

## SketchUp missing or detected but MCP unavailable

Use desktop SketchUp with DWG import support. Discovery checks running-process paths, uninstall metadata, App Paths and common install folders without assuming a fixed version or drive. Installation alone does not prove importer availability or an active bridge.

Follow [Ringo-Sketchup-MCP's official instructions](https://github.com/Ringophilia/Ringo-Sketchup-MCP) to configure/start the bridge and authorized Ruby execution, then check `bridge_status` and `model_get_info` in Codex. Verify the intended profile, model and instance before writes. The tested bridge was 1.3.2 with environment caveats documented in [Tested Environment](TESTED_ENVIRONMENT.md). No bridge code/binaries are bundled here; other bridges require compatibility review.

Ringo files plus a loopback listener are only hints. Missing hints produce UNKNOWN, not a claim that all possible bridges are absent. Authenticated connection, Ruby and native import are checked by Skill PRE-FLIGHT, not this file detector. No tokens or full configuration are emitted.

## Skill installs but CAD to SketchUp does not work

Level 1 is file installation. Level 2 requires desktop automation dependencies, design parameters and live PRE-FLIGHT. `READY` under **Skill Installation** means the Skill file was found. `UNKNOWN` under **Full Automation** means key runtime capabilities remain unverified; `NOT_READY` means a checked requirement failed. The checker intentionally cannot certify full READY from software presence.

Keep the extracted ZIP folder to rerun checks; installer/checker are not copied into the Skill runtime. Remove local paths/account names before sharing diagnostics, and never send passwords, tokens or private CAD files.
