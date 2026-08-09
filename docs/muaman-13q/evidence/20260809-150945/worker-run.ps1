param(
    [string]$SecretsFile, [string]$RunId, [string]$ExpectedUserName,
    [string]$InstallerPath, [string]$WorkRoot, [string]$EvidenceRoot,
    [string]$UiStringsPath, [string]$ConfigPath, [string]$ReferenceDir
)
$ErrorActionPreference = 'Stop'
$secrets = Get-Content -LiteralPath $SecretsFile -Raw -Encoding UTF8 | ConvertFrom-Json
$env:M13Q_OWNER_DISPLAYNAME = $secrets.ownerDisplayName
$env:M13Q_OWNER_USERNAME    = $secrets.ownerUsername
$env:M13Q_OWNER_PASSWORD    = $secrets.ownerPassword
$env:M13Q_RESTRICTED_PATH   = $secrets.restrictedPath
Remove-Item -LiteralPath $SecretsFile -Force -ErrorAction SilentlyContinue
& 'C:\dev\muaman.worktrees\muaman-13q-independent-fresh-user-uninstall-reinstall-acceptance\tools\muaman13q\fresh_user_worker.ps1' -RunId $RunId -ExpectedUserName $ExpectedUserName -InstallerPath $InstallerPath -WorkRoot $WorkRoot -EvidenceRoot $EvidenceRoot -UiStringsPath $UiStringsPath -ConfigPath $ConfigPath -ReferenceDir $ReferenceDir *> 'C:\mu13o-acceptance\m13q\run\20260809-150945\worker-capture.txt'
Write-Output '[wrapper] worker returned without terminating; treating as failure'
exit 1