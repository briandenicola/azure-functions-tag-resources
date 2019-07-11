#!/bin/bash

export RG=$1
export functionHostName=$2
export functionName=$3

eventSubscriptionName="ResourceCreationTracker003"

# 
# Must be run after the Function App has been deployed
#
#az login

#Get Master Key for Functions
userName=$(az functionapp deployment list-publishing-profiles -n $functionHostName -g $RG --query '[0].userName' --output tsv)
userPassword=$(az functionapp deployment list-publishing-profiles -n $functionHostName -g $RG --query '[0].userPWD' --output tsv)
kuduUrl=$(az functionapp deployment list-publishing-profiles -n $functionHostName -g $RG --query '[0].publishUrl' --output tsv)

adminUrl="https://$kuduUrl/api/functions/admin/token"
keyUrl="https://$functionHostName.azurewebsites.net/admin/host/keys/_master"

JWT=$(curl -s -X GET -u $userName:$userPassword $adminUrl | tr -d '"')
key=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" -d "Content-Length: 0" $keyUrl | jq -r '.value')

# Create Event Grid Subscription
subId="$(az account show -o tsv --query id)"
resourceId="/subscriptions/$subId/resourceGroups/$RG"
az eventgrid event-subscription create --name $eventSubscriptionName \
    --source-resource-id $resourceId \
    --endpoint "https://$functionHostName.azurewebsites.net/runtime/webhooks/eventgrid?functionName=$functionName&code=$key" \
    --included-event-types "Microsoft.Resources.ResourceWriteSuccess"
