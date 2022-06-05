$websiteConfigurationFile = 'TestEshopWP.ps1'
if ([string]::IsNullOrEmpty($env:FREELANCE_LOCAL_CONFIGURATION_PATH)) {
    throw "The freelance local configuration path is not defined."
}
$projectDirectory = (Get-Item (Get-Location)).Parent.Parent
$sourceDirectory = "$projectDirectory/Source"
$pluginsDirectory = "$($sourceDirectory)/plugins"
$themesDirectory = "$($sourceDirectory)/themes"
$currentPath = Get-Location
$wordpressDockerComposePath = "$((Get-Item $currentPath).Parent.Parent)/Wordpress"
$websiteConfigurationFullPath = Join-path -Path $env:FREELANCE_LOCAL_CONFIGURATION_PATH -ChildPath $websiteConfigurationFile
. $websiteConfigurationFullPath

Set-Location $wordpressDockerComposePath
Write-Output "creating env..."
New-Item -Path . -Name ".env" -ItemType "file"
Write-Output "env created"

Write-Output "Extracting powershell environment variables..."
Get-ChildItem env: | ForEach-Object -Process {
    if (-Not ($_.Name.Contains(".") -or $_.Name.Contains("(") -or $_.Name.Contains(")"))) {
        Add-Content -Path ./.env -Value "$($_.Name)=$($_.Value)"
    }
}
Write-Output "Powershell environment variables extracted"

Set-Location -Path $sourceDirectory
Write-Output "Installing themes and plugins..."
composer install
composer update
Write-Output "Plugins and themes installed..."

Set-Location -Path $pluginsDirectory
Write-Output "compressing plugins..."
tar -cvzf plugins.tar.gz .
Write-Output "plugins compressed"

Set-Location -Path $themesDirectory
Write-Output "compressing themes..."
tar -cvzf themes.tar.gz .
Write-Output "plugins compressed"

Set-Location -Path $wordpressDockerComposePath
docker-compose down
docker-compose build --no-cache wordpress
docker-compose up -d
if (Test-Path -Path ./.env) {
    Write-Output 'removing env...'
    Remove-Item .env
    Write-Output 'env removed'
}
if (Test-Path -Path "$($pluginsDirectory)/plugins.tar.gz") {
    Write-Output "removing plugins.tar.gz..."
    Remove-Item -Path "$($pluginsDirectory)/plugins.tar.gz"
    Write-Output "Removed plugins.tar.gz"
}

if (Test-Path -Path "$($themesDirectory)/themes.tar.gz") {
    Write-Output "removing themes.tar.gz..."
    Remove-Item -Path "$($themesDirectory)/themes.tar.gz"
    Write-Output "Removed themes.tar.gz"
}

Set-Location $currentPath

Write-Output "Activating plugins..."
../Plugins/Activate.ps1
Write-Output "Plugins activation ended"