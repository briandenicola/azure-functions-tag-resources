[CmdletBinding()]
param($eventGridEvent, $TriggerMetadata)

function Get-ServicePrincipalDisplayName {
    param(
        [string] $appId
    )

    Set-Variable -Name KNOWN_APPID -Value @(
        @{ Appid='60e6cd67-9c8c-4951-9b3c-23c25a2169af'; DisplayName='Azure Compute Resource Provider'},
        @{ Appid='8edd93e1-2103-40b4-bd70-6e34e586362d'; DisplayName='Windows Azure Security Resource Provider'},
        @{ Appid='a6aa9161-5291-40bb-8c5c-923b567bee3b'; DisplayName='Storage Resource Provider'},
        @{ Appid='76cd24bf-a9fc-4344-b1dc-908275de6d6d'; DisplayName='Azure SQL Virtual Network to Network Resource Provider'},
        @{ Appid='57c0fc58-a83a-41d0-8ae9-08952659bdfd'; DisplayName='Azure Cosmos DB Virtual Network To Network Resource Provider'}
    ) -Option Constant

    try {
        $knownApplication = $KNOWN_APPID | Where-Object Appid -eq $appId
        if( $null -eq $knownApplication ) {
            $DisplayName = Get-AzADServicePrincipal -Applicationid $appId | Select-Object -ExpandProperty DisplayName
        } else {
            $DisplayName = $knownApplication.DisplayName
        }
    }
    catch {
        Write-Verbose -Message  ("[{0}] - Received Error of unknown type. . ." -f $(Get-Date))
        $DisplayName = $appId
    }

    return $DisplayName
}

$subscription = $ENV:AZURE_SUBSCRIPTION_NAME
$creatorTypeTagName = "CreatorType"
$creatorTagName = "CreatedBy"

Write-Verbose -Message ("[{0}] - {1}: EventGrid Event Received . . . " -f $(Get-Date), $eventGridEvent.eventType)

if( $eventGridEvent.eventType -eq "Microsoft.Resources.ResourceWriteSuccess" ) {   

    #Login to Azure is handled at the Function Host Level defined by the profile.ps1 file 
    Select-AzSubscription -SubscriptionName $subscription | Out-Null
    
    $resourceId = $eventGridEvent.data.resourceUri
    $resource = Get-AzResource -ResourceId $resourceId

    if( $null -eq $resource ) {
        Write-Verbose -Message ("[{0}] - Could find {1}" -f $(Get-Date), $resourceId )
        return 
    }
    
    $tags = $resource.Tags
    if( $tags.Keys -notcontains $creatorTagName ) { 
        Write-Verbose -Message  ("[{0}] - {1}: {2} tag is not defined . . ." -f $(Get-Date), $resource.Name, $creatorTagName)

        if( -not [string]::IsNullOrEmpty($eventGridEvent.data.claims.name) ) {
            $creatorType = "User"
            $resourceCreator = $eventGridEvent.data.claims.name
        } elseif( -not [string]::IsNullOrEmpty($eventGridEvent.data.claims.appid)) {
            $creatorType = "Service Principal"
            $resourceCreator = Get-ServicePrincipalDisplayName -appId $eventGridEvent.data.claims.appid 
        } else {
            $creatorType = "Unknown"
            $resourceCreator = "Unknown"
        }

        Write-Verbose -Message ("[{0}] - {1}: Setting {2} Tag to `'{3}`' ({4})" -f $(Get-Date), $resource.Name, $creatorTagName, $resourceCreator, $resourceId )
        $tags.Add($creatorTypeTagName, $creatorType) 
        $tags.Add($creatorTagName, $resourceCreator) 

        return $resourceCreator
        Set-AzResource -ResourceId $resourceId -Tag $tags -Force
    }
}