[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Alias('Mode')][ValidateSet('Status', 'Collect', 'Install')][string]$Action = 'Status',
    [string]$PrivateRoot,
    [string]$ProjectRoot
)

# Only explicit manifest files cross the public/private workspace boundary.
# No Git commands, deletion propagation, credential discovery or force overwrite.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# Windows PowerShell 5.1 Get-FileHash internally uses Add-Member; inherited
# WhatIf can suppress that read-only bookkeeping. Handle preview explicitly.
$previewOnly = [bool]$WhatIfPreference
$WhatIfPreference = $false

function FullPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}
function IsUnder([string]$Path, [string]$Root) {
    return $Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase) -or
        $Path.StartsWith($Root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}
function CheckRelative([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.Contains('\') -or
        $Path -match '[:*?"<>|\x00-\x1f]' -or [IO.Path]::IsPathRooted($Path)) {
        throw "Invalid manifest path: $Path"
    }
    $parts = $Path.Split('/')
    foreach ($part in $parts) {
        if ($part -in @('', '.', '..') -or $part.EndsWith('.') -or $part.EndsWith(' ') -or
            $part -match '^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)' -or
            $part -match '^(?i:\.git|\.sync|__pycache__|node_modules|\.env(?:\..*)?|auth\.json|config\.toml|credentials(?:\..*)?|secrets?(?:\..*)?|token(?:\..*)?)$') {
            throw "Forbidden manifest path: $Path"
        }
    }
    if ($Path -cnotmatch '^\.agents/skills/[^/]+/.+$' -and
        $Path -cnotmatch '^\.codex/agents/[^/]+\.toml$') {
        throw "Path is outside the workspace allowlist: $Path"
    }
}

function CheckLinks([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            # Cloud placeholders are reparse points too. Reject only links that
            # redirect the namespace, not cloud-file tags such as 0x9000601a.
            if ($item.LinkType -in @('SymbolicLink', 'Junction')) {
                throw "Linked path is not allowed: $cursor"
            }
            if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
                if (-not ('WorkspaceSync.Reparse' -as [type])) {
                    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
namespace WorkspaceSync {
    public static class Reparse {
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        static extern SafeFileHandle CreateFileW(string p, uint a, uint s, IntPtr sec, uint c, uint f, IntPtr t);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern bool DeviceIoControl(SafeFileHandle h, uint c, IntPtr i, uint n, byte[] o, uint z, out uint b, IntPtr v);
        public static bool IsNameSurrogate(string path) {
            using (var handle = CreateFileW(path, 0, 7, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero)) {
                if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
                var buffer = new byte[16384]; uint count;
                if (!DeviceIoControl(handle, 0x000900a8, IntPtr.Zero, 0, buffer, (uint)buffer.Length, out count, IntPtr.Zero))
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                return (BitConverter.ToUInt32(buffer, 0) & 0x20000000) != 0;
            }
        }
    }
}
'@
                }
                if ([WorkspaceSync.Reparse]::IsNameSurrogate($cursor)) { throw "Redirected path is not allowed: $cursor" }
            } else { throw "Reparse path is not supported on this platform: $cursor" }
        }
        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
}
function FileHash([string]$Path) {
    CheckLinks $Path
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Expected a regular file: $Path" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function EnsureDirectory([string]$Path) {
    CheckLinks $Path
    [IO.Directory]::CreateDirectory($Path) | Out-Null
    CheckLinks $Path
}
function PublishFile([string]$Source, [string]$Destination, $SourceHash, $DestinationHash) {
    CheckLinks $Destination
    $directory = Split-Path -Parent $Destination
    EnsureDirectory $directory
    $temporary = Join-Path $directory ('.workspace-sync-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        if ((FileHash $Source) -ne $SourceHash -or (FileHash $Destination) -ne $DestinationHash) {
            throw "File changed during synchronization: $Destination"
        }
        [IO.File]::Copy($Source, $temporary, $false)
        if ((FileHash $temporary) -ne $SourceHash -or (FileHash $Source) -ne $SourceHash -or
            (FileHash $Destination) -ne $DestinationHash) { throw "File changed while preparing copy: $Destination" }
        CheckLinks $Destination
        if ($null -eq $DestinationHash) { [IO.File]::Move($temporary, $Destination) }
        else { [IO.File]::Replace($temporary, $Destination, [NullString]::Value) }
        if ((FileHash $Destination) -ne $SourceHash) { throw "Post-copy verification failed: $Destination" }
    } finally {
        # This exact GUID file was created by this invocation; never delete an
        # input file or recursively clean any workspace directory.
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

$lock = $null
try {
    if (-not $PrivateRoot) { $PrivateRoot = Split-Path -Parent $PSScriptRoot }
    $PrivateRoot = FullPath $PrivateRoot
    if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent $PrivateRoot }
    $ProjectRoot = FullPath $ProjectRoot
    if ((IsUnder $ProjectRoot $PrivateRoot) -or
        (IsUnder $PrivateRoot (Join-Path $ProjectRoot '.agents')) -or
        (IsUnder $PrivateRoot (Join-Path $ProjectRoot '.codex'))) {
        throw 'Project/private roots overlap a synchronization source.'
    }
    CheckLinks $PrivateRoot
    CheckLinks $ProjectRoot
    foreach ($root in @($PrivateRoot, $ProjectRoot)) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Missing root directory: $root" }
    }
    $manifestPath = Join-Path $PrivateRoot 'workspace-manifest.json'
    $statePath = Join-Path $PrivateRoot '.sync/state.json'
    $workspace = Join-Path $PrivateRoot 'workspace'
    $manifestHash = FileHash $manifestPath
    if ($null -eq $manifestHash) { throw 'workspace-manifest.json is missing.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.files -isnot [Array] -or $manifest.files.Count -eq 0) {
        throw 'Invalid manifest: expected schemaVersion 1 and a nonempty files array.'
    }
    $seen = @{}
    foreach ($relative in $manifest.files) {
        if ($relative -isnot [string]) { throw 'Manifest entries must be strings.' }
        CheckRelative $relative
        if ($seen.ContainsKey($relative)) { throw "Duplicate manifest path: $relative" }
        $seen[$relative] = $true
    }
    $stateHash = FileHash $statePath
    $bases = @{}
    if ($null -ne $stateHash) {
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($state.schemaVersion -ne 1 -or $state.files -isnot [PSCustomObject]) { throw 'Invalid synchronization state schema.' }
        foreach ($property in $state.files.PSObject.Properties) {
            CheckRelative $property.Name
            if ($property.Value -isnot [string] -or $property.Value -notmatch '^[0-9a-fA-F]{64}$') {
                throw "Invalid state hash for: $($property.Name)"
            }
            $bases[$property.Name] = $property.Value
        }
    }
    $rows = @()
    $blocked = $false
    foreach ($relative in $manifest.files) {
        $projectPath = Join-Path $ProjectRoot $relative
        $privatePath = Join-Path $workspace $relative
        $projectHash = FileHash $projectPath
        $privateHash = FileHash $privatePath
        $base = $bases[$relative]
        if ($null -ne $projectHash -and $projectHash -eq $privateHash) { $status = 'Synced' }
        elseif ($base -and ($null -eq $projectHash -or $null -eq $privateHash)) { $status = 'Missing' }
        elseif ($null -eq $projectHash -and $null -eq $privateHash) { $status = 'Missing' }
        elseif ($null -eq $privateHash) { $status = 'CollectNeeded' }
        elseif ($null -eq $projectHash) { $status = 'InstallNeeded' }
        elseif (-not $base) { $status = 'Conflict' }
        elseif ($privateHash -eq $base) { $status = 'CollectNeeded' }
        elseif ($projectHash -eq $base) { $status = 'InstallNeeded' }
        else { $status = 'Conflict' }
        $row = [PSCustomObject]@{ Path = $relative; Status = $status; ProjectPath = $projectPath;
            PrivatePath = $privatePath; ProjectHash = $projectHash; PrivateHash = $privateHash }
        $rows += $row
        Write-Output ("{0,-15} {1}" -f $status, $relative)
        if ($status -in @('Conflict', 'Missing') -or
            ($Action -eq 'Collect' -and $status -eq 'InstallNeeded') -or
            ($Action -eq 'Install' -and $status -eq 'CollectNeeded')) { $blocked = $true }
    }
    if ($blocked) {
        throw 'Preflight blocked: reconcile differing files or missing paths manually; no copies or state changes were made.'
    }
    if ($Action -eq 'Status') { exit 0 }
    if ($previewOnly) {
        Write-Output "WhatIf: $Action would synchronize the above manifest files and record matching hashes; nothing was written."
        exit 0
    }
    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, "$Action manifest workspace files and record matching hashes")) { exit 0 }

    $stateDirectory = Split-Path -Parent $statePath
    EnsureDirectory $stateDirectory
    $lockPath = Join-Path $stateDirectory 'sync.lock'
    CheckLinks $lockPath
    $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    if ((FileHash $statePath) -ne $stateHash -or (FileHash $manifestPath) -ne $manifestHash) {
        throw 'Manifest or synchronization state changed after preflight; retry from Status.'
    }
    foreach ($row in $rows) {
        if ((FileHash $row.ProjectPath) -ne $row.ProjectHash -or (FileHash $row.PrivatePath) -ne $row.PrivateHash) {
            throw "File changed after preflight: $($row.Path)"
        }
    }
    foreach ($row in $rows) {
        if ($row.Status -eq 'CollectNeeded') {
            PublishFile $row.ProjectPath $row.PrivatePath $row.ProjectHash $row.PrivateHash
        } elseif ($row.Status -eq 'InstallNeeded') {
            PublishFile $row.PrivatePath $row.ProjectPath $row.PrivateHash $row.ProjectHash
        }
    }
    $nextBases = [ordered]@{}
    foreach ($row in $rows) {
        $projectHash = FileHash $row.ProjectPath
        $privateHash = FileHash $row.PrivatePath
        if ($null -eq $projectHash -or $projectHash -ne $privateHash) {
            throw "Files changed before state update: $($row.Path). Some copies may already have completed."
        }
        $nextBases[$row.Path] = $projectHash
    }
    $nextState = [ordered]@{ schemaVersion = 1; files = $nextBases } | ConvertTo-Json -Depth 6
    $stateTemporary = Join-Path $stateDirectory ('.workspace-sync-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($stateTemporary, $nextState + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
        if ((FileHash $statePath) -ne $stateHash) { throw 'Synchronization state changed before publication.' }
        CheckLinks $statePath
        if ($null -eq $stateHash) { [IO.File]::Move($stateTemporary, $statePath) }
        else { [IO.File]::Replace($stateTemporary, $statePath, [NullString]::Value) }
    } finally { if ([IO.File]::Exists($stateTemporary)) { [IO.File]::Delete($stateTemporary) } }
    Write-Output "$Action completed. All manifest files match; Git staging/commit/push remain separate."
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.WriteLine('Synchronization stopped. Inspect Status before retrying; I/O failures are not a multi-file transaction.')
    exit 1
} finally {
    if ($null -ne $lock) { $lock.Dispose() }
}
