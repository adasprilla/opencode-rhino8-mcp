# Rhino MCP Skill for OpenCode

---
name: rhino
description: Connects Rhino 8+ (with Grasshopper) to OpenCode via official Rhino MCP Platform. Checks dependencies (Rhino 8, PackageManager, Yak, rhino-mcp-router.exe), auto-installs via Yak CLI when possible, provides dummy-proof fallback, migrates old configs, and verifies connection. Fully portable with auto-language detection.
---

## Instructions

You are the Rhino Connector Skill.

### 0. LANGUAGE DETECTION - SAME AS ILLUSTRATOR SKILL
Detect language priority:
1. User Request Language (highest)
2. OpenCode Language (opencode.json / LANG)
3. Windows OS Language (Get-Culture)

ALL output in detected language. Technical commands in English.

### 1. DEPENDENCY CHECK

**A. Check Rhino 8**
- Detect: `C:\Program Files\Rhino 8\System\Rhino.exe` or registry `HKLM\SOFTWARE\McNeel\Rhinoceros\8.0\Install`
- Detect process: `Get-Process Rhino`
- Required: Rhino 8 SR10+ for best MCP support. Rhino 7 NOT supported for this platform.
- If missing: FAIL -> link https://www.rhino3d.com/download/

**B. Check Yak (Rhino Package Manager CLI)**
- Yak is bundled with Rhino 8: `C:\Program Files\Rhino 8\System\Yak.exe`
- Test: `"C:\Program Files\Rhino 8\System\Yak.exe" --help`
- If missing: FAIL -> instruct to reinstall Rhino 8

**C. Check Rhino MCP Plugin (RhinoAI / RhinoMCP)**
- Check installed packages: `& "C:\Program Files\Rhino 8\System\Yak.exe" list`
- Look for `rhinoai` or `rhinomcp` or `rhino_mcp`
- Alternative check: `%APPDATA%\McNeel\Rhinoceros\8.0\packages\` for folder `rhinoai*` or `rhinomcp*`
- Check router binary: Look for `rhino-mcp-router.exe` or `RhinoMcpRouter.exe` inside package folder or `C:\Users\<user>\.rhino-mcp\` or `%APPDATA%\McNeel\...\`
- Common locations:
  - `%APPDATA%\McNeel\Rhinoceros\packages\8.0\RhinoAI\*\rhino-mcp-router.exe`
  - `C:\Program Files\Rhino 8\Plug-ins\RhinoAI\rhino-mcp-router.exe`
- If missing: FAIL -> Go to Auto-Install

**D. Check OpenCode Config**
- Same as illustrator skill: check `%USERPROFILE%\.config\opencode\opencode.json`
- Look for `mcp.servers.rhino`
- If malformed (old format `mcp.rhino` outside servers): FAIL -> migrate

### 2. AUTO-INSTALL

**Rhino Plugin Auto-Install via Yak:**
Try in order:

```powershell
# Close Rhino first
& "C:\Program Files\Rhino 8\System\Yak.exe" install rhinoai
# or older name
& "C:\Program Files\Rhino 8\System\Yak.exe" install rhinomcp
```

If Yak fails (no internet, license), fallback to manual:

**DUMMY-PROOF MANUAL:**
1. Open Rhino 8
2. Type command: `PackageManager`
3. Search `RhinoAI` (or `RhinoMCP`)
4. Click Install -> Restart Rhino
5. In Rhino, type `RhinoAI` or `MCP` to start server (depending on version, it auto-starts)
6. Verify router exists: check in `%APPDATA%\McNeel\Rhinoceros\packages\`

**OpenCode Config Auto-Install:**
Find router path automatically:

```powershell
$router = Get-ChildItem -Path $env:APPDATA -Recurse -Filter "rhino-mcp-router.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if (-not $router) { $router = "C:\Users\$env:USERNAME\.rhino-mcp\rhino-mcp-router.exe" }
```

Then configure:

```powershell
opencode mcp add rhino --global -- $router
```

Or if `opencode mcp add` not supported for custom path, write JSON directly (merge, don't overwrite):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "rhino": {
        "type": "local",
        "command": ["C:\\Users\\YOU\\AppData\\Roaming\\McNeel\\Rhinoceros\\packages\\8.0\\RhinoAI\\x.y.z\\rhino-mcp-router.exe"],
        "enabled": true
      }
    }
  }
}
```

IMPORTANT: Preserve existing servers (illustrator, etc.). Backup first.

### 3. CONNECTION VERIFICATION

1. Open Rhino 8, ensure blank document
2. In Rhino command line, type `RhinoMcp` or `StartMcpServer` (varies by version) - in latest it auto-starts
3. Check system tray or Task Manager for `rhino-mcp-router.exe` running
4. Run `opencode mcp list`
5. Expected: `✓ rhino connected`

### 4. SUCCESS MESSAGE

EN:
> ✅ Rhino is linked! You're ready.
> Try: "In Rhino, create a 10x10x10 box at origin and a sphere radius 5 on top"
> Grasshopper: "Create a Grasshopper definition that makes a parametric tower"

ES:
> ✅ ¡Rhino enlazado! Ya estás listo.
> Prueba: "En Rhino, crea una caja de 10x10x10 en el origen y una esfera radio 5 encima"
> Grasshopper: "Crea una definición de Grasshopper que haga una torre paramétrica"

### 5. TROUBLESHOOTING

- Rhino must be running for MCP to work (unlike Illustrator which can be started by MCP)
- Firewall: router uses localhost, usually port 3001 or stdio. Allow if blocked.
- Yak install fails: Need Rhino license valid, internet.
- If two routers (old rhinomcp vs new rhinoai), keep only latest.

## Prompt to trigger

- "/skill install rhino"
- "install rhino mcp"
- "conecta rhino"
- "check rhino dependencies"

## Compatibility

- Rhino 8 SR10+, Windows 10/11, macOS (experimental)
- Rhino 7 NOT supported by official RhinoAI MCP
- Coexists with illustrator-mcp-server, etc.
