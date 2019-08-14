#https://github.com/prolsen/o365/blob/master/o365auditor.py

param($eventGridEvent, $TriggerMetadata)

Set-Variable -Name COMPUTE_RESOURCE_PROVIDER -Value '60e6cd67-9c8c-4951-9b3c-23c25a2169af' -Option Constant

$subscription = $ENV:AZURE_SUBSCRIPTION_NAME
$creatorTypeTagName = "CreatorType"
$creatorTagName = "CreatedBy"

Write-Host ("Received EventGrid Event of type {0}" -f $eventGridEvent.eventType)

if( $eventGridEvent.eventType -eq "Microsoft.Resources.ResourceWriteSuccess" ) {   

    #Login to Azure is handled at the Function Host Level defined by the profile.ps1 file 
    Select-AzSubscription -SubscriptionName $subscription
    
    $resourceId = $eventGridEvent.data.resourceUri
    $resource = Get-AzResource -ResourceId $resourceId
    
    Write-Host ("[{0}] - {1}: Received write event" -f $(Get-Date), $resource.Name)

    $resourceCreator = "Undetermined"
    if( -not [string]::IsNullOrEmpty($eventGridEvent.data.claims.name) ) {
        $creatorType = "User"
        $resourceCreator = $eventGridEvent.data.claims.name
    } else {
        if(  $eventGridEvent.data.claims.appid  -eq $COMPUTE_RESOURCE_PROVIDER ) {
            $creatorType = "Azure Compute Resource Provider"
        }
        else {
            $creatorType = "Service Principal"
        }
        $resourceCreator = $eventGridEvent.data.claims.appid 
    }

    $tags = $resource.tags
    if( $tags.Keys -notcontains $creatorTagName ) { 
        Write-Host ("[{0}] - {1}: Setting {2} Tag to `'{3}`' ({4})" -f $(Get-Date), $resource.Name, $creatorTagName, $resourceCreator, $resourceId )
        $tags.Add($creatorTypeTagName, $creatorType) 
        $tags.Add($creatorTagName, $resourceCreator) 
        Set-AzResource -ResourceId $resourceId -Tag $tags -Force
    }
}