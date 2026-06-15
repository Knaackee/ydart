param(
  [string]$YrsSourceDir = $env:YRS_SOURCE_DIR,
  [string[]]$Targets = @("arm64-v8a", "armeabi-v7a", "x86_64"),
  [switch]$Release = $true
)

$ErrorActionPreference = "Stop"

if (-not $YrsSourceDir) {
  $YrsSourceDir = Join-Path (Split-Path $PSScriptRoot -Parent) "..\y-crdt"
}

$YffiDir = Join-Path $YrsSourceDir "yffi"
if (-not (Test-Path -LiteralPath $YffiDir)) {
  throw "Cannot find yffi at '$YffiDir'. Set YRS_SOURCE_DIR to a y-crdt checkout."
}

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
  throw "Cannot find cargo. Install Rust with rustup first."
}

function Initialize-MsvcEnvironment {
  $RunningOnWindows = ($PSVersionTable.PSEdition -eq "Desktop") -or ($IsWindows -eq $true)
  if (-not $RunningOnWindows) {
    return
  }
  $Msvcrt = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio", "C:\Program Files\Microsoft Visual Studio" -Recurse -Filter msvcrt.lib -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\lib\\x64\\msvcrt\.lib$" } |
    Select-Object -First 1
  $Kernel32 = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\Lib" -Recurse -Filter kernel32.lib -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\um\\x64\\kernel32\.lib$" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
  $Ucrt = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\Lib" -Recurse -Filter ucrt.lib -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\ucrt\\x64\\ucrt\.lib$" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
  $Link = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio", "C:\Program Files\Microsoft Visual Studio" -Recurse -Filter link.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\bin\\Hostx64\\x64\\link\.exe$" } |
    Select-Object -First 1

  if ($Msvcrt -and $Kernel32 -and $Ucrt) {
    $env:LIB = "$($Msvcrt.DirectoryName);$($Kernel32.DirectoryName);$($Ucrt.DirectoryName);$env:LIB"
  }
  if ($Link) {
    $env:PATH = "$($Link.DirectoryName);$env:PATH"
  }
}

Initialize-MsvcEnvironment

rustup toolchain install nightly | Out-Host
rustup target add --toolchain nightly aarch64-linux-android armv7-linux-androideabi x86_64-linux-android | Out-Host

$Root = Split-Path $PSScriptRoot -Parent
$Profile = if ($Release) { "release" } else { "debug" }
$TargetMap = @{
  "arm64-v8a" = @{
    RustTarget = "aarch64-linux-android"
    Linker = "aarch64-linux-android23-clang.cmd"
  }
  "armeabi-v7a" = @{
    RustTarget = "armv7-linux-androideabi"
    Linker = "armv7a-linux-androideabi23-clang.cmd"
  }
  "x86_64" = @{
    RustTarget = "x86_64-linux-android"
    Linker = "x86_64-linux-android23-clang.cmd"
  }
}

$YrsLib = Join-Path $YrsSourceDir "yrs\src\lib.rs"
$OriginalYrsLib = Get-Content -LiteralPath $YrsLib -Raw
$NeedsIfLetGuard = Select-String -Path (Join-Path $YrsSourceDir "yrs\src\*.rs") -Pattern "if let .*=>" -Quiet
if ($NeedsIfLetGuard -and $OriginalYrsLib -notmatch "feature\(if_let_guard\)") {
  Set-Content -LiteralPath $YrsLib -Value ("#![feature(if_let_guard)]`n" + $OriginalYrsLib) -NoNewline
}

function Get-NdkRoot {
  if ($env:ANDROID_NDK_HOME) {
    return $env:ANDROID_NDK_HOME
  }
  foreach ($sdk in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
    if (-not $sdk) {
      continue
    }
    $ndkDir = Join-Path $sdk "ndk"
    if (Test-Path -LiteralPath $ndkDir) {
      return Get-ChildItem -Path $ndkDir -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    }
  }
  return $null
}

try {
  $CargoNdk = Get-Command cargo-ndk -ErrorAction SilentlyContinue
  if ($CargoNdk) {
    foreach ($Target in $Targets) {
      Write-Host "Building yffi for Android $Target ($Profile) with cargo-ndk..."
      $CargoArgs = @("+nightly", "ndk", "-t", $Target, "build")
      if ($Release) {
        $CargoArgs += "--release"
      }
      $CargoArgs += @("--manifest-path", (Join-Path $YffiDir "Cargo.toml"))
      & cargo @CargoArgs
      if ($LASTEXITCODE -ne 0) {
        throw "cargo ndk failed for $Target"
      }
    }
  } else {
    Write-Host "cargo-ndk not found; falling back to direct cargo builds with NDK clang."
    $NdkRoot = Get-NdkRoot
    if (-not $NdkRoot) {
      throw "Cannot locate Android NDK. Install cargo-ndk or set ANDROID_NDK_HOME."
    }
    $NdkBin = Join-Path $NdkRoot "toolchains\llvm\prebuilt\windows-x86_64\bin"

    foreach ($Target in $Targets) {
      if (-not $TargetMap.ContainsKey($Target)) {
        throw "Unsupported Android ABI: $Target"
      }
      $RustTarget = $TargetMap[$Target].RustTarget
      $Linker = Join-Path $NdkBin $TargetMap[$Target].Linker
      if (-not (Test-Path -LiteralPath $Linker)) {
        throw "Cannot find Android linker: $Linker"
      }

      $EnvName = "CARGO_TARGET_$($RustTarget.ToUpperInvariant().Replace('-', '_'))_LINKER"
      Set-Item -Path "env:$EnvName" -Value $Linker

      Write-Host "Building yffi for Android $Target ($RustTarget, $Profile) with direct cargo..."
      $CargoArgs = @("+nightly", "build")
      if ($Release) {
        $CargoArgs += "--release"
      }
      $CargoArgs += @("--manifest-path", (Join-Path $YffiDir "Cargo.toml"), "--target", $RustTarget)
      & cargo @CargoArgs
      if ($LASTEXITCODE -ne 0) {
        throw "cargo build failed for $Target"
      }
    }
  }
} finally {
  Set-Content -LiteralPath $YrsLib -Value $OriginalYrsLib -NoNewline
}

$CargoTargetDir = Join-Path $YrsSourceDir "target"
foreach ($Target in $Targets) {
  if (-not $TargetMap.ContainsKey($Target)) {
    throw "Unsupported Android ABI: $Target"
  }
  $RustTarget = $TargetMap[$Target].RustTarget
  $Source = Join-Path $CargoTargetDir "$RustTarget\$Profile\libyrs.so"
  $DestDir = Join-Path $Root "android\src\main\jniLibs\$Target"
  $Dest = Join-Path $DestDir "libyrs.so"
  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Expected Android library not found: $Source"
  }
  New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
  Copy-Item -LiteralPath $Source -Destination $Dest -Force
  Write-Host "Copied $Dest"
}
