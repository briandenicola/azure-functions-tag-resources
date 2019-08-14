param($eventGridEvent, $TriggerMetadata)

$subscription = $ENV:AZURE_SUBSCRIPTION_NAME
$tagName = "Creator"

Write-Host ("Received EventGrid Event of type {0}" -f $eventGridEvent.eventType)

if( $eventGridEvent.eventType -eq "Microsoft.Resources.ResourceWriteSuccess" ) {   

    #Login to Azure is handled at the Function Host Level defined by the profile.ps1 file 
    Select-AzSubscription -SubscriptionName $subscription
    
    $resourceId = $eventGridEvent.data.resourceUri
    $resource = Get-AzResource -ResourceId $resourceId
    
    $resourceCreator = "Undetermined"
    if( -not [string]::IsNullOrEmpty($eventGridEvent.data.claims.name) ) {
        $resourceCreator = $eventGridEvent.data.claims.name
    } else {
        $appid = $eventGridEvent.data.claims.appid 

        if( -not [string]::IsNullOrEmpty($resource.ManagedBy) ) {
            $parent = Get-AzResource -ResourceId $resource.ManagedBy -ErrorAction SilentlyContinue | Out-Null
            if( $parent.Tags.ContainsKey($tagName) ) {
                $resourceCreator = "{0} via {1}" -f $parent.Tags[$tagName], $appid
            } 
        }
        else {
            $resourceCreator = $appid
        }
    }

    $tags = $resource.tags
    if( $tags.Keys -notcontains $tagName ) { 
        Write-Host ("Setting Creator Tag for `'{0}`' on id {1}" -f $resourceCreator, $resourceId )
        $tags.Add($tagName, $resourceCreator) 
        Set-AzResource -ResourceId $resourceId -Tag $tags -Force
    }
}