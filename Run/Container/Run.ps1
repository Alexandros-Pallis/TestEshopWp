$websiteConfigurationPath = 'TestEshopWP.ps1'
if([string]::IsNullOrEmpty($env:FREELANCE_LOCAL_CONFIGURATION_PATH)){
    throw "The freelance local configuration path is not defined."
}
$projectDirectory = (Get-Item (Get-Location)).Parent.Parent
$pluginsDirectory = "$projectDirectory\Plugins"
$websiteConfigurationFullPath = Join-path -Path $env:FREELANCE_LOCAL_CONFIGURATION_PATH -ChildPath $websiteConfigurationPath
$currentPath = Get-Location
$dockerComposePath = (Get-Item $currentPath).Parent.Parent
$websiteConfigurationContent = (Get-Content $websiteConfigurationFullPath -Raw) -replace '\$env:', ''

Set-Location $pluginsDirectory
composer install
Set-Location $pluginsDirectory/wp-content/plugins
# Compress-Archive -Path $pluginsDirectory/wp-content/plugins -DestinationPath $pluginsDirectory/plugins.zip
tar -cvzf plugins.tgz .
Set-Location $currentPath

Set-Location $dockerComposePath
Write-Output "creating env..."
New-Item -Path . -Name ".env" -ItemType "file" -value ''
Out-File -Path ./.env -InputObject $websiteConfigurationContent
Write-Output "env created"
Write-Output "Executing Docker Container Command..."
docker-compose down
docker-compose up -d --build
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