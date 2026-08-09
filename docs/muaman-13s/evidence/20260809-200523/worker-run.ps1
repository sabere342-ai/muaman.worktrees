param(
    [string]$SecretsFile, [string]$RunId, [string]$ExpectedUserName,
    [string]$ConsumerWorkspace, [string]$StagedZip, [string]$EvidenceRoot,
    [string]$UiStringsPath, [string]$ConfigPath
)
$ErrorActionPreference = 'Stop'
$secrets = Get-Content -LiteralPath $SecretsFile -Raw -Encoding UTF8 | ConvertFrom-Json
$env:M13S_OWNER_DISPLAYNAME = $secrets.ownerDisplayName
$env:M13S_OWNER_USERNAME    = $secrets.ownerUsername
$env:M13S_OWNER_PASSWORD    = $secrets.ownerPassword
$env:M13S_RESTRICTED_PATH   = $secrets.restrictedPath
Remove-Item -LiteralPath $SecretsFile -Force -ErrorAction SilentlyContinue
& 'C:\m13s-acceptance\run\20260809-200523\worker\consumer_worker.ps1' -RunId $RunId -ExpectedUserName $ExpectedUserName -ConsumerWorkspace $ConsumerWorkspace -StagedZip $StagedZip -EvidenceRoot $EvidenceRoot -UiStringsPath $UiStringsPath -ConfigPath $ConfigPath *> 'C:\m13s-acceptance\run\20260809-200523\worker-capture.txt'
$donePath = Join-Path $EvidenceRoot 'json\worker-done.json'
$completed = $false
if (Test-Path -LiteralPath $donePath) {
    try {
        $done = Get-Content -LiteralPath $donePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $completed = ($done.allStepsPassed -eq $true)
    } catch {}
}
if ($completed) { Write-Output '[wrapper] worker done: all steps passed'; exit 0 }
Write-Output '[wrapper] worker did not complete successfully'
exit 1