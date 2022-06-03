$websiteConfigurationFile = 'TestEshopWP.ps1'
$containerName = "wordpress-test-eshop"
$wpCliContainerName = "wordpress-cli"
if([string]::IsNullOrEmpty($env:FREELANCE_LOCAL_CONFIGURATION_PATH)){
    throw "The freelance local configuration path is not defined."
}
$projectDirectory = (Get-Item (Get-Location)).Parent.Parent
$pluginsDirectory = "$projectDirectory\Plugins"
$currentPath = Get-Location
$dockerComposePath = (Get-Item $currentPath).Parent.Parent
$websiteConfigurationFullPath = Join-path -Path $env:FREELANCE_LOCAL_CONFIGURATION_PATH -ChildPath $websiteConfigurationFile
. $websiteConfigurationFullPath

Set-Location $pluginsDirectory
composer install
composer update
$plugins = Get-ChildItem -Path $pluginsDirectory/wp-content/plugins -Directory
Set-Location $pluginsDirectory/wp-content/plugins
Write-Output "compressing plugins..."
tar -cvzf .\plugins.tgz .
Write-Output "Plugins compressed"
Set-Location $currentPath

Set-Location $dockerComposePath
Write-Output "creating env..."
New-Item -Path . -Name ".env" -ItemType "file"
Write-Output "env created"

Write-Output "Extracting powershell environment variables..."
Get-ChildItem env: | ForEach-Object -Process {
    if(-Not ($_.Name.Contains(".") -or $_.Name.Contains("(") -or $_.Name.Contains(")"))){
        Add-Content -Path ./.env -Value "$($_.Name)=$($_.Value)"
    }
}
Write-Output "Powershell environment variables extracted"

Write-Output "Executing Docker Container Command..."
docker-compose down
docker-compose up -d --build
# docker cp $pluginsDirectory/wp-content/plugins/plugins.tgz ${containerName}:/var/www/html/wp-content/plugins
docker exec $containerName tar Ccf ${$pluginsDirectory}/wp-content/plugins/plugins.tgz | tar Cxf /var/www/html/wp-content/plugins
# Activate plugins
Write-Output "Activating plugins..."
# $plugins | ForEach-Object -Process {
#     Write-Output "Activating Plugin: $($_.Name)"
#     docker-compose run --rm $wpCliContainerName wp plugin activate $_.Name
# }
Write-Output "Plugins activated"
Write-Output "Docker Conainer executed"
if(Test-Path -Path ./.env){
    Write-Output 'removing env...'
    Remove-Item .env
    Write-Output 'env removed'
}
if(Test-Path -Path $pluginsDirectory/wp-content/plugins/plugins.tgz){
    Remove-Item $pluginsDirectory/wp-content/plugins/plugins.tgz
}
Set-Location $currentPath