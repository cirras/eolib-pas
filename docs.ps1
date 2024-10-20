#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot

if (-not (Test-Path variable:IsWindows) -or $IsWindows) {
  $PasDoc = 'pasdoc.exe'
} else {
  $PasDoc = 'pasdoc'
}

try {
  if ($null -eq (Get-Command $PasDoc -ErrorAction SilentlyContinue)) {
    Write-Error "$PasDoc is not on the PATH. Please install it or add it to the PATH."
  }

  & ./dist.ps1

  $SourceFiles = Get-ChildItem -Path "./dist" -Filter *.pas | ForEach-Object { $_.FullName }
  $OutputFolder = "./docs/output"

  if (Test-Path $OutputFolder) {
    Remove-Item -Recurse -Force $OutputFolder
  }
  New-Item -ItemType Directory -Path $OutputFolder

  Copy-Item -Path './docs/logo.svg' -Destination './docs/output/logo.svg'

  & $PasDoc `
    "--use-tipue-search" `
    "--write-uses-list" `
    "--auto-abstract" `
    "--css" "./docs/style.css" `
    "--html-head" "./docs/head.html" `
    "--introduction" "./docs/introduction.txt" `
    "--output" $OutputFolder `
    @SourceFiles

  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate docs with PasDoc."
  }
}
finally {
  Pop-Location
}

Write-Host "Docs generated successfully."