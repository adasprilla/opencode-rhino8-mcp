#Requires -Version 5.1
# Rhino MCP - One-Click Installer for OpenCode - UNIVERSAL
# Based on official McNeel RhinoAI / RhinoMCP Platform
# Docs: https://mcneel.github.io/RhinoAI/docs/getting-started/

$ErrorActionPreference = "Stop"

function Get-UserLang {
    try { $c = (Get-Culture).Name; if ($c -like "es*") { return "es" } } catch {}
    return "en"
}
$Lang = Get-UserLang
function Write-Msg($type, $en, $es) {
    $m = if ($Lang -eq "es") { $es } else { $en }
    if ($type -eq "ok") { Write-Host "✓ $m" -ForegroundColor Green }
    elseif ($type -eq "warn") { Write-Host "⚠ $m" -ForegroundColor Yellow }
    elseif ($type -eq "err") { Write-Host "✗ $m" -ForegroundColor Red }
    else { Write-Host $m }
}

Write-Host ""
Write-Msg "info" "Rhino MCP Installer for OpenCode" "Instalador Rhino MCP para OpenCode"
Write-Host "----------------------------------------"

# 1. CHECK RHINO 8
$rhinoExe = "C:\Program Files\Rhino 8\System\Rhino.exe"
$yakExe = "C:\Program Files\Rhino 8\System\Yak.exe"

if (-not (Test-Path $rhinoExe)) {
    Write-Msg "err" "Rhino 8 not found at $rhinoExe" "Rhino 8 no encontrado en $rhinoExe"
    Write-Host "Download: https://www.rhino3d.com/download/" -ForegroundColor Cyan
    exit 1
}
Write-Msg "ok" "Rhino 8 found" "Rhino 8 encontrado"

if (-not (Test-Path $yakExe)) {
    Write-Msg "err" "Yak not found (Rhino 8 system corrupted)" "Yak no encontrado"
    exit 1
}

# 2. FIND ROUTER (before install, maybe already there)
function Find-RhinoRouter {
    $paths = @(
        "$env:APPDATA\McNeel\Rhinoceros\packages\8.0\",
        "$env:APPDATA\McNeel\Rhinoceros\8.0\packages\",
        "$env:USERPROFILE\.rhino-mcp\",
        "C:\Program Files\Rhino 8\Plug-ins\"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $found = Get-ChildItem -Path $p -Recurse -Filter "rhino-mcp-router.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { return $found.FullName }
            $found2 = Get-ChildItem -Path $p -Recurse -Filter "RhinoMcpRouter.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found2) { return $found2.FullName }
        }
    }
    return $null
}

$routerPath = Find-RhinoRouter

# 3. AUTO-INSTALL VIA YAK IF NEEDED
if (-not $routerPath) {
    Write-Msg "warn" "Rhino MCP plugin not found, installing via Yak..." "Plugin Rhino MCP no encontrado, instalando via Yak..."
    
    # Close Rhino if running (Yak needs it closed)
    $rhinoProc = Get-Process -Name "Rhino" -ErrorAction SilentlyContinue
    if ($rhinoProc) {
        Write-Msg "warn" "Please close Rhino to install plugin, then press Enter" "Por favor cierra Rhino para instalar, luego presiona Enter"
        Read-Host "Press Enter when closed / Presiona Enter cuando cerrado"
    }

    try {
        Write-Host "Running: Yak install rhinoai" -ForegroundColor Gray
        & $yakExe install rhinoai 2>&1 | Write-Host
        Start-Sleep -Seconds 2
        $routerPath = Find-RhinoRouter
    } catch {}

    if (-not $routerPath) {
        try {
            Write-Host "Trying alternative name: rhinomcp" -ForegroundColor Gray
            & $yakExe install rhinomcp 2>&1 | Write-Host
            Start-Sleep -Seconds 2
            $routerPath = Find-RhinoRouter
        } catch {}
    }

    if (-not $routerPath) {
        Write-Msg "err" "Auto-install failed. Manual steps:" "Instalacion auto fallo. Pasos manuales:"
        Write-Host "  1. Open Rhino 8 -> Command: PackageManager" -ForegroundColor Cyan
        Write-Host "  2. Search 'RhinoAI' -> Install -> Restart Rhino" -ForegroundColor Cyan
        Write-Host "  3. Run this script again" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Abre Rhino 8 -> Comando: PackageManager" -ForegroundColor Cyan
        Write-Host "  2. Busca 'RhinoAI' -> Instalar -> Reinicia Rhino" -ForegroundColor Cyan
        Write-Host "  3. Corre este script de nuevo" -ForegroundColor Cyan
        exit 1
    }
}

Write-Msg "ok" "Router found: $routerPath" "Router encontrado: $routerPath"

# 4. CONFIGURE OPENCODE - UNIVERSAL MIGRATION
$configPath = "$env:USERPROFILE\.config\opencode\opencode.json"
$backupPath = "$env:USERPROFILE\.config\opencode\opencode.backup.json"

if (-not (Test-Path (Split-Path $configPath))) { New-Item -ItemType Directory -Path (Split-Path $configPath) -Force | Out-Null }

if (Test-Path $configPath) {
    Copy-Item $configPath $backupPath -Force
    $jsonRaw = Get-Content $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($jsonRaw)) { $jsonRaw = "{}" }
    $existing = $jsonRaw | ConvertFrom-Json
} else {
    $existing = [PSCustomObject]@{ mcp = [PSCustomObject]@{ servers = [PSCustomObject]@{} } }
}

if (-not $existing.mcp) { $existing | Add-Member -NotePropertyName mcp -NotePropertyValue ([PSCustomObject]@{ servers = [PSCustomObject]@{} }) }
if (-not $existing.mcp.servers) { $existing.mcp | Add-Member -NotePropertyName servers -NotePropertyValue ([PSCustomObject]@{} ) -Force }

# Migrate old configs: mcp.<name> outside servers -> mcp.servers.<name>
$propsToMigrate = @()
foreach ($prop in $existing.mcp.PSObject.Properties) {
    if ($prop.Name -ne "servers" -and $prop.Name -ne "`$schema") {
        if ($prop.Value -and ($prop.Value.PSObject.Properties['command'] -or $prop.Value.PSObject.Properties['type'])) {
            $propsToMigrate += $prop.Name
        }
    }
}
foreach ($name in $propsToMigrate) {
    Write-Msg "warn" "Migrating old config: mcp.$name -> mcp.servers.$name" "Migrando: mcp.$name -> mcp.servers.$name"
    $oldServer = $existing.mcp.$name
    if ($oldServer.PSObject.Properties['enabled']) { $oldServer.PSObject.Properties.Remove('enabled') }
    if (-not $existing.mcp.servers.PSObject.Properties[$name]) {
        $existing.mcp.servers | Add-Member -NotePropertyName $name -NotePropertyValue $oldServer -Force
    }
    $existing.mcp.PSObject.Properties.Remove($name)
}

# Add Rhino
$existing.mcp.servers | Add-Member -NotePropertyName "rhino" -NotePropertyValue ([PSCustomObject]@{
    type = "local"
    command = @($routerPath)
}) -Force

$existing | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
Write-Msg "ok" "Config saved: $configPath" "Config guardada: $configPath"

# 5. VERIFY
Write-Msg "info" "Verifying..." "Verificando..."
try {
    $out = & opencode mcp list 2>&1 | Out-String
    Write-Host $out
} catch {
    Write-Msg "warn" "Could not run opencode mcp list. Make sure OpenCode is in PATH" "No se pudo correr opencode mcp list"
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
if ($Lang -eq "es") {
    Write-Host "✅ ¡Rhino enlazado!" -ForegroundColor Green
    Write-Host "1. Abre Rhino 8" -ForegroundColor White
    Write-Host "2. Corre: opencode" -ForegroundColor White
    Write-Host "3. Di: En Rhino, crea una caja de 10x10x10 en el origen" -ForegroundColor White
    Write-Host ""
    Write-Host "Nota: Rhino debe estar abierto para que funcione. Illustrator puede abrirse solo." -ForegroundColor DarkGray
} else {
    Write-Host "✅ Rhino linked!" -ForegroundColor Green
    Write-Host "1. Open Rhino 8" -ForegroundColor White
    Write-Host "2. Run: opencode" -ForegroundColor White
    Write-Host "3. Say: In Rhino, create a 10x10x10 box at origin" -ForegroundColor White
}
Write-Host "=================================================" -ForegroundColor Cyan
