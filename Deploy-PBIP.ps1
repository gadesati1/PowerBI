[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$ApplicationId,

    [Parameter(Mandatory=$true)]
    [string]$secPwd,

    [Parameter(Mandatory=$true)]
    [string]$PBIXSourceDir,

    [Parameter(Mandatory=$true)]
    [string]$WorkSpaceName
)

## Make sure the workspace name is already created and Add Service Principle as Administrator/Contributor to that workspace.
## This script uses Fabrick rest APIs which requires fabrick workspace licensing.

$workingFolder = "$PBIXSourceDir"

New-Item -ItemType Directory -Path "$workingFolder\modules" -ErrorAction SilentlyContinue | Out-Null

Write-Host "##[debug]Downloading FabricPS-PBIP module"

 @(
     "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1",
     "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1") |% {
         
         Invoke-WebRequest -Uri $_ -OutFile "$workingFolder\modules\$(Split-Path $_ -Leaf)"

     }

 Write-Host "##[debug]Installing Az.Accounts"

 if(-not (Get-Module Az.Accounts -ListAvailable)){
     Install-Module Az.Accounts -Scope CurrentUser -Force
 }


$path = "$PBIXSourceDir\PBIP-Reports"
$appId = $ApplicationId
$appSecret = $secPwd
$tenantId = $TenantId                                        

#$pbipSemanticModelPath = "$path\[Semantic Model folder name].SemanticModel"
#$pbipReportPath = "$path\[Report folder name].Report"

Import-Module "$workingFolder\modules\FabricPS-PBIP" -Force


Write-Host "##[debug]Authentication with SPN"

Set-FabricAuthToken -servicePrincipalId $appId -servicePrincipalSecret $appSecret -tenantId $tenantId -reset                        

Write-Host "##[debug]Ensure Fabric Workspace & permissions"

$workspaceId = New-FabricWorkspace  -name $WorkSpaceName -skipErrorIfExists

#Set-FabricWorkspacePermissions $workspaceId $workspacePermissions

#Write-Host "##[debug]Publish Semantic Model"

#$semanticModelImport = Import-FabricItem -workspaceId $workspaceId -path $pbipSemanticModelPath

#Write-Host "##[debug]Publish Report"

# Import the report and ensure its binded to the previous imported report

#$reportImport = Import-FabricItem -workspaceId $workspaceId -path $pbipReportPath -itemProperties @{"semanticModelId"=$semanticModelImport.Id}

$reports = Get-ChildItem -Directory -Path $path

foreach($report in $reports)
{
    Write-Host "##[debug]Publishing Report from $path\$report"
    $import = Import-FabricItems -workspaceId $workspaceId -path "$path\$report"
}
