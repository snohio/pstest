$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$cmdLogPath = 'C:\temp.log'
$expectedCmdLines = @(
    'blorvak snerf quillop',
    'zantik moop farnel',
    'glimber trox vendle',
    'wuzzle prang dorfic'
)
$cmdCommand = '(echo blorvak snerf quillop)&(echo zantik moop farnel)&(echo glimber trox vendle)&(echo wuzzle prang dorfic) 2>&1'

# Mirrors amazon-cloudwatch-agent-ctl.ps1: bare "cmd" resolved through PATH, piped to Out-File.
& cmd /c $cmdCommand | Out-File -FilePath $cmdLogPath -Encoding ascii
$cmdExitCode = $LASTEXITCODE
if ($cmdExitCode -ne 0) {
    throw "cmd.exe failed with exit code $cmdExitCode"
}

$actualCmdLines = @(Get-Content -LiteralPath $cmdLogPath)
if ($actualCmdLines.Count -ne 4 -or (Compare-Object -ReferenceObject $expectedCmdLines -DifferenceObject $actualCmdLines -SyncWindow 0)) {
    throw "$cmdLogPath did not contain the expected four lines"
}

$result = [ordered]@{
    message = 'pstest script ran successfully'
    computer_name = $env:COMPUTERNAME
    powershell_version = $PSVersionTable.PSVersion.ToString()
    process_id = $PID
    cmd_exit_code = $cmdExitCode
    cmd_log_path = $cmdLogPath
    cmd_log_line_count = $actualCmdLines.Count
    executed_at_utc = [DateTime]::UtcNow.ToString('o')
}

$json = $result | ConvertTo-Json
$json | Set-Content -LiteralPath 'C:\chef-pstest\result.json' -Encoding Ascii

Write-Output "pstest: cmd.exe wrote $cmdLogPath"
$actualCmdLines | ForEach-Object { Write-Output "temp.log: $_" }
Write-Output $json
Write-Output 'pstest: wrote C:\chef-pstest\result.json'
