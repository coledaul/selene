[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $true)]
    [string]$GithubEnvironmentFile
)

$ErrorActionPreference = "Stop"

$archiveName = "ffmpeg-kit-windows-x86_64-full-8.1.2.zip"
$archiveUrl = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/8.1.2-full/$archiveName"
$expectedSha256 = "bc9653b6fae63f86ecd4338a6b4eed56bcca57bd84f3fcf214b3cec8490046ea"
$archivePath = Join-Path ([System.IO.Path]::GetTempPath()) $archiveName

if (Test-Path -LiteralPath $OutputDirectory) {
    Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDirectory | Out-Null

try {
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath

    $actualSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "FFmpegKit archive SHA-256 mismatch"
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $OutputDirectory

    $requiredDll = Join-Path $OutputDirectory "bin/libffmpegkit.dll"
    if (-not (Test-Path -LiteralPath $requiredDll -PathType Leaf)) {
        throw "FFmpegKit archive does not contain bin/libffmpegkit.dll"
    }

    Add-Content -LiteralPath $GithubEnvironmentFile -Value "FFMPEGKIT_LOCAL_DIR=$OutputDirectory" -Encoding utf8
}
finally {
    Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
}
