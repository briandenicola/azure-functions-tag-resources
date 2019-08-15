## Overview

This repo shows how to use Azure Functions with Event Grid to tag resources with the user name who created the resource

## Flow 
* When a resource is created in a Resource Group (defined in the $RG variable), an event is raised by Event Grid
* The raised Event will trigger an Azure Function 
* The function will query the resource for all defined Tags.
* If a tag named Creator is not defined then it will add the new tag. 
    * The tag value will equal $eventGridEvent.data.claims.name or $eventGridEvent.data.claims.appid passed by Event Grid to the Function

## Setup
1. ./Infrastructure/create_infrastructure.sh $RG $location $functionHostName $subscriptionName
2. Deploy Function Code in EventGridTrigger Folder.
    * Use either Visual Studio Code or Azure Function cli to deploy the code
3. ./Infrastructure/create_event_subscription.sh $RG $functionHostName $functionName
4. ./Infrastructure/assign_azuread_permission.ps1 -functionappName $functionName
    * This script is optional. 
    * This will allow the Function App to do a look up an Service Principal's DisplayName
    * It will assign Directory.Read.All permission in Azure AD's Graph API.
    * Admin Conset must be granted after the permission has been set in Azure AD
