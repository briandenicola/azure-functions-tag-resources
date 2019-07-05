param($eventGridEvent, $TriggerMetadata)

$tenantId = $ENV:AZURE_TENANTID
$subscription = $ENV:AZURE_SUBSCRIPTION_NAME
$clientId = $ENV:AZURE_CLIENTID

Write-Host ("Received EventGrid Event of type {0}" -f $eventGridEvent.eventType)

if( $eventGridEvent.eventType -eq "Microsoft.Resources.ResourceWriteSuccess" ) {   
    Write-Host ("Logging into Azure as {0}" -f $clientid)    

    $passwd = ConvertTo-SecureString $ENV:AZURE_CLIENTSECRET -AsPlainText -Force
    $pscredential = New-Object System.Management.Automation.PSCredential( $clientid, $passwd)

    Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantId
    Select-AzSubscription -SubscriptionName $subscription
    
    $resourceId = $eventGridEvent.data.resourceUri
    $resourceCreator = $eventGridEvent.data.claims.name

    $tags = (Get-AzResource -ResourceId $resourceId).tags

    if( $tags.Keys -notcontains "Creator" ) { 
        Write-Host ("Setting Creator Tag for `'{0}`' on id {1}" -f $resourceCreator, $resourceId )
        $tags.Add("Creator", $resourceCreator) 
        Set-AzResource -ResourceId $resourceId -Tag $tags -Force
    }
}