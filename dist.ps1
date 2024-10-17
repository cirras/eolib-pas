#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot

if (-not (Test-Path variable:IsWindows) -or $IsWindows) {
  $Generator = 'Generator.exe'
} else {
  $Generator = 'Generator'
}

try {
  if ($null -eq (Get-Command lazbuild -ErrorAction SilentlyContinue)) {
    Write-Error "lazbuild is not on the PATH. Please install it or add it to the PATH."
  }
  
  if (Test-Path -Path "dist") {
    Remove-Item -Recurse -Force "dist"
  }
  
  & lazbuild protocol-code-generator/Generator.lpi
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build protocol code generator."
  }
  
  & "protocol-code-generator/$Generator" --source-directory=eo-protocol/xml --output-directory=dist
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate protocol code."
  }
  
  Get-ChildItem -Path "src" -File | Copy-Item -Destination "dist" -Force
  Copy-Item -Path "LICENSE" -Destination "dist" -Force
  
  Write-Host "Dist completed successfully."
} finally {
  Pop-Location
}