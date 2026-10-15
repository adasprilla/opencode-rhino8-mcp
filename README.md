# opencode-rhino8-mcp

> One-click installer to connect Rhino 8 (with Grasshopper) to OpenCode via official McNeel RhinoAI MCP Platform. Coexists with Illustrator MCP and others. Auto-migrates old configs.

Gist installer: https://gist.github.com/adasprilla/814ebeb4acb2bea0046cecee8596cc70
Docs: https://mcneel.github.io/RhinoAI/docs/getting-started/

---

### Install in 30 seconds

**Option A - Fast (1 command)**

Open PowerShell (Windows + R > powershell) and paste:

```powershell
irm https://gist.githubusercontent.com/adasprilla/814ebeb4acb2bea0046cecee8596cc70/raw/install-rhino.ps1 | iex
```

**Option B - Safe (file)**

Download install-rhino.ps1 from this repo and run: Right-click > Run with PowerShell.

### Requirements

- Rhino 8 SR10+ licensed and installed (Rhino 7 not supported by official RhinoAI MCP)
- Windows 10/11 (macOS experimental by McNeel)
- OpenCode v2+

### Verify

1. Open Rhino 8 (blank document)
2. In Rhino command line, check if MCP server auto-starts (latest versions do). If not, run command `RhinoAI` or `StartMcpServer`
3. Open PowerShell, run: `opencode mcp list`
4. You should see: rhino connected

If you also use Illustrator:

```
rhino        connected
illustrator  connected
```

### First tests

Inside OpenCode:

```
In Rhino, create a 10x10x10 box at origin and a sphere radius 5 on top of it
```

Grasshopper:

```
Create a Grasshopper definition that makes a parametric tower with 10 floors, each rotated 5 degrees
```

Spanish:

```
En Rhino, crea una caja de 10x10x10 en el origen y una esfera de radio 5 encima
```

### What the installer does

- Auto-detects language (ES/EN)
- Checks Rhino 8 installation and Yak.exe (Rhino Package Manager CLI)
- Searches for rhino-mcp-router.exe in AppData
- If not found, installs via Yak: `Yak install rhinoai` (official McNeel plugin)
- Fallback to manual if Yak fails: instructs PackageManager > RhinoAI
- Backups opencode.json to opencode.backup.json
- Migrates old MCP configs (mcp.rhino, mcp.illustrator, mcp.blender, etc.) to new format mcp.servers.* instead of deleting
- Preserves coexistence with illustrator-mcp-server and others
- Verifies with opencode mcp list

### Difference vs Illustrator MCP

- Illustrator: needs Node.js + npm install illustrator-mcp-server (community)
- Rhino 8: no Node.js needed, uses official binary rhino-mcp-router.exe included in RhinoAI plugin
- Rhino must be open for MCP to work. Illustrator can be auto-started by MCP.

### Manual install (if auto fails)

1. Open Rhino 8 -> Command: `PackageManager`
2. Search `RhinoAI` -> Install -> Restart Rhino
3. Find router path:
```powershell
Get-ChildItem -Path $env:APPDATA -Recurse -Filter "rhino-mcp-router.exe"
```
4. Configure OpenCode:
```powershell
opencode mcp add rhino --global -- "C:\Path\To\rhino-mcp-router.exe"
```

### Files

- install-rhino.ps1 - Universal installer (recommended)
- rhino.md - Skill definition for OpenCode skills folder (~/.config/opencode/skills/)
- README.md - This file

### Troubleshooting

- Yak install fails: Check internet, Rhino license valid, close Rhino before Yak install
- Router not found after install: Restart Rhino, check %APPDATA%\McNeel\Rhinoceros\packages\8.0\RhinoAI\
- Firewall: router uses localhost/stdio, allow if blocked
- opencode mcp list shows not connected: Ensure Rhino is open, ensure no old router process stuck in Task Manager

### Related

- Illustrator MCP: https://github.com/adasprilla/opencode-illustrator-mcp
- Official McNeel RhinoAI: https://github.com/mcneel/RhinoAI
- Official Docs: https://mcneel.github.io/RhinoAI/docs/getting-started/

### Credits

- MCP Platform: McNeel / RhinoAI (MIT)
- Skill + Universal Migrator: adasprilla
- Based on official docs: https://mcneel.github.io/RhinoAI/docs/getting-started/

### License

MIT
