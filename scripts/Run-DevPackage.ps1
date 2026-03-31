$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "src\Sefirah\Sefirah.csproj"
$appPackagesRoot = Join-Path $repoRoot "src\Sefirah\AppPackages"
$msixPath = Join-Path $appPackagesRoot "Sefirah_2.4.0.0_x64_Debug_Test\Sefirah_2.4.0.0_x64_Debug.msix"
$registrationRoot = Join-Path $appPackagesRoot "_dev_register"
$legacyRegistrationRoot = Join-Path $repoRoot "_msix_inspect"
$zipPath = Join-Path $appPackagesRoot "_dev_register.zip"
$manifestPath = Join-Path $registrationRoot "AppxManifest.xml"

$buildArgs = @(
    "msbuild", $projectPath,
    "/t:Rebuild",
    "/p:Configuration=Debug",
    "/p:TargetFramework=net9.0-windows10.0.26100",
    "/p:Platform=x64",
    "/p:RuntimeIdentifier=win-x64",
    "/p:DevPackage=true",
    "/p:UapAppxPackageBuildMode=Sideloading",
    "/p:GenerateAppxPackageOnBuild=true",
    "/p:AppxBundle=Never",
    "/p:AppxPackageDir=AppPackages\\",
    "/p:AppxPackageSigningEnabled=false"
)

Write-Host "Building Sefirah Dev..."
& dotnet @buildArgs

if (-not (Test-Path $msixPath)) {
    throw "Expected package not found: $msixPath"
}

$existingPkg = Get-AppxPackage "matej.Sefirah.Dev" -ErrorAction SilentlyContinue
if ($existingPkg) {
    Write-Host "Removing existing dev package..."
    Remove-AppxPackage -Package $existingPkg.PackageFullName
}

if (Test-Path $registrationRoot) {
    Remove-Item -Recurse -Force $registrationRoot
}

if (Test-Path $legacyRegistrationRoot) {
    Remove-Item -Recurse -Force $legacyRegistrationRoot
}

if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Write-Host "Preparing package layout..."
Copy-Item $msixPath $zipPath
Expand-Archive -LiteralPath $zipPath -DestinationPath $registrationRoot
Remove-Item -Force $zipPath

Write-Host "Registering package..."
Add-AppxPackage -Register $manifestPath -ForceApplicationShutdown

$pkg = Get-AppxPackage "matej.Sefirah.Dev"
if (-not $pkg) {
    throw "Registered package matej.Sefirah.Dev was not found."
}

$appId = "$($pkg.PackageFamilyName)!App"

Write-Host "Launching Sefirah Dev..."
Start-Process explorer.exe "shell:AppsFolder\$appId"

Write-Host ""
Write-Host "PackageFamilyName: $($pkg.PackageFamilyName)"
Write-Host "Launch target: shell:AppsFolder\$appId"
