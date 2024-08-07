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

<# Check if MicrosoftPowerBIMgmt module is installed #>
if (-not(Get-InstalledModule -name MicrosoftPowerBIMgmt -ErrorAction silentlycontinue)) {
	Write-Host "Module MicrosoftPowerBIMgmt does not exist - Installing module";
	Install-Module MicrosoftPowerBIMgmt -Force -Scope CurrentUser;
}
else {
	Write-Host "Module MicrosoftPowerBIMgmt exists";
}

$securePassword = $secPwd | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $securePassword
Connect-PowerBIServiceAccount  -ServicePrincipal -Credential $credential -TenantId $TenantId

$workspace = Get-PowerBIWorkspace -Name $WorkSpaceName

if($workspace) {
  Write-Host "The workspace named $WorkSpaceName already exists"
}
else {
  Write-Host "Creating new workspace named $WorkSpaceName"
  $workspace = New-PowerBIGroup -Name $WorkSpaceName
}

foreach ($PowerBIReport in Get-ChildItem -Path $PBIXSourceDir -Recurse | Where-Object $_.Extension -eq ".pbix")
{
    # update script with file path to PBIX file
    $pbixFilePath = $PowerBIReport.FullName

    Write-Host "Deploying $($PowerBIReport.FullName) to $WorkSpaceName"

    $import = New-PowerBIReport -Path $pbixFilePath -Workspace $WorkSpaceName -ConflictAction CreateOrOverwrite

    $import | select *
}
