param(
  [string]$ApiBaseUrl = "http://192.168.123.9:8080",
  [string]$StorageBucket = "",
  [string]$StoragePath = "apk-releases",
  [string]$PublicApkUrl = "",
  [string]$Title = "Доступно обновление HabitDuel",
  [switch]$ForceUpdate,
  [string[]]$Changelog = @(),
  [switch]$SkipBuild,
  [switch]$OpenReleaseFolder
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
$apkSource = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
$releaseDir = Join-Path $projectRoot "build\releases"

function Get-AppVersionInfo {
  param([string]$PubspecPath)

  $versionLine = Get-Content $PubspecPath | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
  if (-not $versionLine) {
    throw "Не удалось найти version в pubspec.yaml"
  }

  $versionValue = ($versionLine -replace '^version:\s*', '').Trim()
  $parts = $versionValue -split '\+'
  $versionName = $parts[0]
  $versionCode = if ($parts.Length -gt 1) { [int]$parts[1] } else { 1 }

  return @{
    VersionName = $versionName
    VersionCode = $versionCode
    VersionFull = $versionValue
  }
}

$version = Get-AppVersionInfo -PubspecPath $pubspecPath
$artifactName = "HabitDuel-v$($version.VersionName)+$($version.VersionCode)-release.apk"
$artifactPath = Join-Path $releaseDir $artifactName
$firestoreJsonPath = Join-Path $releaseDir "android_update.json"
$storageObjectPath = "$StoragePath/$artifactName"

if (-not $SkipBuild) {
  Write-Host ""
  Write-Host "Building APK..." -ForegroundColor Cyan
  & "C:\flutter\bin\flutter.bat" build apk --release "--dart-define=API_BASE_URL=$ApiBaseUrl"
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter build apk завершился с ошибкой."
  }
}

if (-not (Test-Path $apkSource)) {
  throw "APK не найден: $apkSource"
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
Copy-Item -LiteralPath $apkSource -Destination $artifactPath -Force

$resolvedPublicUrl = $PublicApkUrl

if (-not [string]::IsNullOrWhiteSpace($StorageBucket)) {
  $gsutil = Get-Command gsutil -ErrorAction SilentlyContinue
  if ($null -ne $gsutil) {
    $bucketUrl = "gs://$StorageBucket/$storageObjectPath"
    Write-Host ""
    Write-Host "Uploading APK to Firebase Storage bucket..." -ForegroundColor Cyan
    & $gsutil.Source cp $artifactPath $bucketUrl
    if ($LASTEXITCODE -ne 0) {
      throw "Загрузка APK в Storage завершилась с ошибкой."
    }

    if ([string]::IsNullOrWhiteSpace($resolvedPublicUrl)) {
      Write-Host ""
      Write-Host "APK загружен в: $bucketUrl" -ForegroundColor Green
      Write-Host "Теперь получите download URL в Firebase Console и повторно запустите скрипт с -PublicApkUrl" -ForegroundColor Yellow
    }
  }
  else {
    Write-Host ""
    Write-Host "gsutil не найден. APK собран локально, но автозагрузка пропущена." -ForegroundColor Yellow
    Write-Host "Файл для загрузки: $artifactPath"
  }
}

$payload = [ordered]@{
  enabled = $true
  title = $Title
  versionName = $version.VersionName
  versionCode = $version.VersionCode
  apkUrl = $resolvedPublicUrl
  forceUpdate = [bool]$ForceUpdate
  changelog = $Changelog
}

$payload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $firestoreJsonPath -Encoding UTF8

Write-Host ""
Write-Host "Release artifact:" -ForegroundColor Green
Write-Host $artifactPath
Write-Host ""
Write-Host "Firestore document: app_config/android_update" -ForegroundColor Cyan
Write-Host "Payload file:" -ForegroundColor Cyan
Write-Host $firestoreJsonPath
Write-Host ""
Get-Content $firestoreJsonPath

if ($OpenReleaseFolder) {
  Invoke-Item $releaseDir
}
