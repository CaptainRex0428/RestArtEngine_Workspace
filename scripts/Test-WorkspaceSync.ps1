[CmdletBinding()]
param([string]$SyncScript)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $SyncScript) { $SyncScript = Join-Path $PSScriptRoot 'Sync-Workspace.ps1' }
$script:checks = 0
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('RAEngineWorkspaceSync-' + [Guid]::NewGuid().ToString('N'))
$shell = (Get-Process -Id $PID).Path
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function TextFile([string]$Path, [string]$Text) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}
function Manifest([string]$Private, [string[]]$Paths) {
    TextFile (Join-Path $Private 'workspace-manifest.json') (
        [ordered]@{ schemaVersion = 1; files = @($Paths) } | ConvertTo-Json -Depth 5)
}
function Fixture([string]$Name) {
    $project = Join-Path $testRoot $Name
    $private = Join-Path $project 'local'
    [IO.Directory]::CreateDirectory($private) | Out-Null
    Manifest $private @('.agents/skills/test/SKILL.md', '.codex/agents/test.toml')
    return [PSCustomObject]@{ Project = $project; Private = $private }
}
function Run($Fixture, [string]$Action = 'Status', [bool]$Success = $true, [string]$Extra = '') {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $shell
    $start.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $SyncScript + '" -ProjectRoot "' +
        $Fixture.Project + '" -PrivateRoot "' + $Fixture.Private + '" -Action ' + $Action + ' ' + $Extra
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $process.Start() | Out-Null
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $code = $process.ExitCode
    $process.Dispose()
    Assert (($code -eq 0) -eq $Success) ("Unexpected exit $code for $Action in $($Fixture.Project):`n$stdout`n$stderr")
    return $stdout + $stderr
}
function Seed($Fixture) {
    TextFile (Join-Path $Fixture.Project '.agents/skills/test/SKILL.md') ("agent baseline`r`nChinese: " + [char]0x4e2d + [char]0x6587)
    TextFile (Join-Path $Fixture.Project '.codex/agents/test.toml') 'name = "test"'
    Run $Fixture 'Collect' | Out-Null
}
try {
    $first = Fixture 'roundtrip'
    Run $first 'Status' $false | Out-Null
    Assert (-not (Test-Path (Join-Path $first.Private '.sync'))) 'Status created local state.'
    Seed $first
    $installed = Join-Path $first.Project '.agents/skills/test/SKILL.md'
    $mirror = Join-Path $first.Private 'workspace/.agents/skills/test/SKILL.md'
    $state = Join-Path $first.Private '.sync/state.json'
    Assert ((Get-FileHash $installed).Hash -eq (Get-FileHash $mirror).Hash) 'Collect changed file bytes.'
    $stateHash = (Get-FileHash $state).Hash
    Run $first | Out-Null
    Assert ((Get-FileHash $state).Hash -eq $stateHash) 'Status changed state.'
    TextFile $installed 'project revision'
    Run $first 'Install' $false | Out-Null
    Assert ([IO.File]::ReadAllText($installed) -eq 'project revision') 'Wrong direction destroyed project change.'
    Run $first 'Collect' $true '-WhatIf' | Out-Null
    Assert ([IO.File]::ReadAllText($mirror) -ne 'project revision') 'WhatIf copied files.'
    Assert ((Get-FileHash $state).Hash -eq $stateHash) 'WhatIf changed state.'
    Run $first 'Collect' | Out-Null
    Assert ([IO.File]::ReadAllText($mirror) -eq 'project revision') 'Collect missed project change.'
    TextFile $mirror 'private revision'
    Run $first 'Collect' $false | Out-Null
    Run $first 'Install' | Out-Null
    Assert ([IO.File]::ReadAllText($installed) -eq 'private revision') 'Install missed private change.'

    # Conflict in the second row must prevent the otherwise valid first copy.
    TextFile $installed 'next project revision'
    $peerInstalled = Join-Path $first.Project '.codex/agents/test.toml'
    $peerMirror = Join-Path $first.Private 'workspace/.codex/agents/test.toml'
    TextFile $peerInstalled 'project peer'
    TextFile $peerMirror 'private peer'
    $stateHash = (Get-FileHash $state).Hash
    Run $first 'Collect' $false | Out-Null
    Assert ([IO.File]::ReadAllText($mirror) -eq 'private revision') 'Conflict allowed an earlier partial copy.'
    Assert ((Get-FileHash $state).Hash -eq $stateHash) 'Conflict updated state.'
    Run $first 'Install' $false | Out-Null
    TextFile $peerMirror 'project peer'
    Run $first 'Collect' | Out-Null
    Assert ([IO.File]::ReadAllText($mirror) -eq 'next project revision') 'Manual resolution could not synchronize.'
    [IO.File]::Delete($peerInstalled)
    Run $first 'Install' $false | Out-Null
    Assert (-not [IO.File]::Exists($peerInstalled)) 'Deletion was silently restored despite established base.'
    Assert ([IO.File]::Exists($peerMirror)) 'Deletion propagated to private copy.'

    $fresh = Fixture 'fresh-install'
    TextFile (Join-Path $fresh.Private 'workspace/.agents/skills/test/SKILL.md') 'private initial'
    TextFile (Join-Path $fresh.Private 'workspace/.codex/agents/test.toml') 'name = "private"'
    Run $fresh 'Install' $true '-WhatIf' | Out-Null
    Assert (-not (Test-Path (Join-Path $fresh.Private '.sync'))) 'Fresh WhatIf created state directory.'
    Run $fresh 'Install' | Out-Null
    Assert ([IO.File]::ReadAllText((Join-Path $fresh.Project '.agents/skills/test/SKILL.md')) -eq 'private initial') 'Fresh install failed.'

    $unknown = Fixture 'initial-conflict'
    TextFile (Join-Path $unknown.Project '.agents/skills/test/SKILL.md') 'local existing'
    TextFile (Join-Path $unknown.Private 'workspace/.agents/skills/test/SKILL.md') 'remote existing'
    TextFile (Join-Path $unknown.Project '.codex/agents/test.toml') 'new agent'
    Run $unknown 'Collect' $false | Out-Null
    Assert (-not (Test-Path (Join-Path $unknown.Private 'workspace/.codex/agents/test.toml'))) 'Initial conflict allowed partial copy.'

    $invalid = Fixture 'invalid'
    foreach ($path in @('AGENTS.md', '../.agents/skills/test/SKILL.md', '/.agents/skills/test/SKILL.md', 'C:/.agents/skills/test/SKILL.md', '.codex/config.toml',
        '.agents/skills/foo/../../secret.md', '.agents/skills/foo/.env', '.agents/skills/foo/credentials.json',
        '.agents/skills/foo/file:stream', '.agents/skills/foo/nul.txt', '.agents\skills\foo\SKILL.md')) {
        Manifest $invalid.Private @($path)
        Run $invalid 'Collect' $false | Out-Null
    }
    Manifest $invalid.Private @('.agents/skills/test/SKILL.md', '.agents/skills/test/SKILL.md')
    Run $invalid 'Collect' $false | Out-Null
    Manifest $invalid.Private @('.agents/skills/test/SKILL.md')
    TextFile (Join-Path $invalid.Private 'workspace-manifest.json') '{"schemaVersion":2,"files":[".agents/skills/test/SKILL.md"]}'
    Run $invalid 'Collect' $false | Out-Null

    $badState = Fixture 'bad-state'
    Seed $badState
    foreach ($broken in @('{broken', '{"schemaVersion":2,"files":{}}',
        '{"schemaVersion":1,"files":{".agents/skills/test/SKILL.md":"not-a-hash"}}',
        '{"schemaVersion":1,"files":{"../secret":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}}')) {
        TextFile (Join-Path $badState.Private '.sync/state.json') $broken
        Run $badState 'Collect' $false | Out-Null
    }
    $overlap = [PSCustomObject]@{ Project = $badState.Project; Private = $badState.Project }
    Run $overlap 'Collect' $false | Out-Null
    $overlap = [PSCustomObject]@{ Project = $badState.Project; Private = (Join-Path $badState.Project '.agents/private') }
    Run $overlap 'Collect' $false | Out-Null

    # Junction creation needs no elevated symlink privilege on Windows.
    $links = Fixture 'links'
    TextFile (Join-Path $links.Project '.agents/skills/test/SKILL.md') 'safe'
    $outside = Join-Path $testRoot 'outside'
    TextFile (Join-Path $outside 'test.toml') 'outside sentinel'
    [IO.Directory]::CreateDirectory((Join-Path $links.Project '.codex')) | Out-Null
    $junction = Join-Path $links.Project '.codex/agents'
    New-Item -ItemType Junction -Path $junction -Target $outside | Out-Null
    Run $links 'Collect' $false | Out-Null
    Assert (-not (Test-Path (Join-Path $links.Private 'workspace/.agents/skills/test/SKILL.md'))) 'Source junction allowed partial copy.'
    Assert ([IO.File]::ReadAllText((Join-Path $outside 'test.toml')) -eq 'outside sentinel') 'Source junction touched outside data.'
    [IO.Directory]::Delete($junction)
    TextFile (Join-Path $links.Project '.codex/agents/test.toml') 'safe agent'
    $destinationJunction = Join-Path $links.Private 'workspace'
    New-Item -ItemType Junction -Path $destinationJunction -Target $outside | Out-Null
    Run $links 'Collect' $false | Out-Null
    Assert (-not (Test-Path (Join-Path $outside '.agents/skills/test/SKILL.md'))) 'Destination junction wrote outside data.'
    [IO.Directory]::Delete($destinationJunction)

    # A locked state prevents writes after otherwise successful preflight.
    $locked = Fixture 'locked'
    Seed $locked
    TextFile (Join-Path $locked.Project '.agents/skills/test/SKILL.md') 'change under lock'
    $heldLock = [IO.File]::Open((Join-Path $locked.Private '.sync/sync.lock'), 'Open', 'ReadWrite', 'None')
    try { Run $locked 'Collect' $false | Out-Null } finally { $heldLock.Dispose() }
    Assert ([IO.File]::ReadAllText((Join-Path $locked.Private 'workspace/.agents/skills/test/SKILL.md')) -ne 'change under lock') 'Lock contention allowed copy.'

    Write-Output "PASS: $script:checks checks; fixtures retained at $testRoot"
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.WriteLine("FAIL: fixtures retained at $testRoot")
    exit 1
}
