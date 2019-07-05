## Overview

This repo shows how to use Azure Functions with Event Grid to tag resources with the user name who created the resource

## Flow 
* When a resource is created in a Resource Group (defined in the $RG variable), an event is raised by Event Grid
* The raised Event will trigger an Azure Function 
* The function will query the resource for all defined Tags.
* If a tag named Creator is not defined then it will add the new tag. 
    * The tag value will equal $eventDataType.data.claims.name passed by Event Grid to the Function

## Pre-requsistes 
* A Service Principal that can log into Azure and has contributor rights

## Setup
1. ./Infrastructure/create_infrastructure.sh $RG $location $functionHostName $subscriptionName $clientId $clientSecret
2. Deploy Function Code in EventGridTrigger Folder.
    * Use either Visual Studio Code or Azure Function cli to deploy the code
3. ./Instrastructure/create_event_subscription.sh $RG $functionHostName $$functionName