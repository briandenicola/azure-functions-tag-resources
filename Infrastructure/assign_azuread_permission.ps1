param(
    [string] $FunctionAppName
)

Import-Module AzureAD
Connect-AzureAD

$graphAppId     = "00000002-0000-0000-c000-000000000000"
$permissionName = "Directory.Read.All"

$msi = Get-AzADServicePrincipal -DisplayName $FunctionAppName
$graphApiSpn = Get-AzureADServicePrincipal -Filter "appId eq '$graphAppId'"
$appRole = $graphApiSpn.AppRoles | Where-Object Value -eq $PermissionName

New-AzureAdServiceAppRoleAssignment -ObjectId $msi.id -PrincipalId $msi.id -ResourceId $graphApiSpn.ObjectId -Id $appRole.Id 