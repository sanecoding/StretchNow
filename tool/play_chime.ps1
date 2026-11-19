# Install chimes. Called from android/app/build.gradle.kts / build.gradle.
#   -Mode play            after assemble (≈ Flutter "√ Built …apk")
#   -Mode watchUninstall  stays alive after Gradle exits; rings when
#                         the package disappears (Flutter "Uninstalling old version...")
param(
    [ValidateSet('play', 'watchUninstall')]
    [string]$Mode = 'play',
    [string]$Package = ''
)

function Play-Chime {
    $wav = 'C:\Windows\Media\Ring10.wav'
    if (-not (Test-Path -LiteralPath $wav)) {
        return
    }
    $lock = Join-Path $env:TEMP 'flutter-install-chime.lock'
    if (Test-Path -LiteralPath $lock) {
        $age = (Get-Date) - (Get-Item -LiteralPath $lock).LastWriteTime
        if ($age.TotalSeconds -lt 1.5) {
            return
        }
    }
    Set-Content -LiteralPath $lock -Value (Get-Date).ToString('o')
    try {
        $player = New-Object System.Media.SoundPlayer $wav
        $player.PlaySync()
    } catch {
    }
}

function Find-Adb {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
        (Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'),
        (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'),
        (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) {
            return $c
        }
    }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    return $null
}

function Test-PackageInstalled {
    param([string]$Adb, [string]$Pkg)
    try {
        $out = & $Adb shell pm path $Pkg 2>$null | Out-String
        return ($out -match 'package:')
    } catch {
        return $false
    }
}

if ($Mode -eq 'play') {
    Play-Chime
    exit 0
}

$adb = Find-Adb
if (-not $adb -or -not $Package) {
    exit 0
}

$deadline = (Get-Date).AddMinutes(4)
$sawInstalled = $false

if (Test-PackageInstalled -Adb $adb -Pkg $Package) {
    $sawInstalled = $true
}

while ((Get-Date) -lt $deadline) {
    $installed = Test-PackageInstalled -Adb $adb -Pkg $Package
    if ($installed) {
        $sawInstalled = $true
    } elseif ($sawInstalled) {
        Play-Chime
        exit 0
    }
    Start-Sleep -Milliseconds 250
}
