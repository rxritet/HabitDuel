param(
  [Parameter(Mandatory = $true)]
  [string]$VersionName,

  [Parameter(Mandatory = $true)]
  [int]$VersionCode,

  [Parameter(Mandatory = $true)]
  [string]$ApkUrl,

  [string]$Title = "Доступно обновление HabitDuel",

  [switch]$ForceUpdate,

  [string[]]$Changelog = @()
)

$payload = [ordered]@{
  enabled = $true
  title = $Title
  versionName = $VersionName
  versionCode = $VersionCode
  apkUrl = $ApkUrl
  forceUpdate = [bool]$ForceUpdate
  changelog = $Changelog
}

$json = $payload | ConvertTo-Json -Depth 4

Write-Host ""
Write-Host "Firestore document: app_config/android_update" -ForegroundColor Cyan
Write-Host ""
Write-Output $json
