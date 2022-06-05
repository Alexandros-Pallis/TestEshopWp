$websiteConfigurationFile = 'TestEshopWP.ps1'
if ([string]::IsNullOrEmpty($env:FREELANCE_LOCAL_CONFIGURATION_PATH)) {
    throw "The freelance local configuration path is not defined."
}
$websiteConfigurationFullPath = Join-path -Path $env:FREELANCE_LOCAL_CONFIGURATION_PATH -ChildPath $websiteConfigurationFile
. $websiteConfigurationFullPath
$projectDirectory = (Get-Item (Get-Location)).Parent.Parent
$pluginsDirectory = "$($projectDirectory)/Source/plugins"
$plugins = Get-ChildItem -Path $pluginsDirectory -Directory
$plugins | ForEach-Object -Process {
    Write-Output "Activating plugin $($_.Name)..."
    docker exec "$($env:COMPOSE_PROJECT_NAME)-wp-cli" wp plugin activate $_.Name
    Write-Output "Activated plugin $($_.Name)"
}
return