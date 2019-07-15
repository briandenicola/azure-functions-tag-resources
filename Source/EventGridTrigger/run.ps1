param($eventGridEvent, $TriggerMetadata)

Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser

$subscription = $ENV:AZURE_SUBSCRIPTION_NAME
$tagName = "Creator"

Write-Host ("Received EventGrid Event of type {0}" -f $eventGridEvent.eventType)

if( $eventGridEvent.eventType -eq "Microsoft.Resources.ResourceWriteSuccess" ) {   

    Connect-AzAccount -Identity
    Select-AzSubscription -SubscriptionName $subscription
    
    $resourceId = $eventGridEvent.data.resourceUri
    $resourceCreator = $eventGridEvent.data.claims.name

    $tags = (Get-AzResource -ResourceId $resourceId).tags

    if( $tags.Keys -notcontains $tagName ) { 
        Write-Host ("Setting Creator Tag for `'{0}`' on id {1}" -f $resourceCreator, $resourceId )
        $tags.Add($tagName, $resourceCreator) 
        Set-AzResource -ResourceId $resourceId -Tag $tags -Force
    }
}