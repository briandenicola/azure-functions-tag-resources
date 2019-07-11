#!/bin/bash

export RG=$1
export location=$2
export functionAppName=$3
export subscriptionName=$4
export clientId=$5
export clientSecret=$6

#az login
az account set -s $subscriptionName
az group create -n $RG -l $location

funcStorageName=${functionAppName}sa001
keyVaultName=${functionAppName}keyvault001

# Create an Azure Function with storage accouunt in the resource group.
az storage account create --name $funcStorageName --location $location --resource-group $RG --sku Standard_LRS
az functionapp create --name $functionAppName \
    --storage-account $funcStorageName \
    --consumption-plan-location $location \
    --resource-group $RG \
    --os-type Windows \
    --runtime powershell
az functionapp identity assign --name $functionAppName --resource-group $RG
functionAppId="$(az functionapp identity show --name $functionAppName --resource-group $RG --query 'principalId' --output tsv)"

# Create Key Vault 
az keyvault create --name $keyVaultName --resource-group $RG --location $location 
az keyvault set-policy --name $keyVaultName --object-id $functionAppId --secret-permissions get

# Set Secret
clientSecretId="$(az keyvault secret set --vault-name $keyVaultName --name clientSecret --value $clientSecret --query 'id' --output tsv)"
tenantId="$(az account show -o tsv --query tenantId)"
az functionapp config appsettings set -g $RG -n $functionAppName --settings AZURE_TENANTID="$tenantId"
az functionapp config appsettings set -g $RG -n $functionAppName --settings AZURE_SUBSCRIPTION_NAME="$subscriptionName"
az functionapp config appsettings set -g $RG -n $functionAppName --settings AZURE_CLIENTID="$clientId"
az functionapp config appsettings set -g $RG -n $functionAppName --settings AZURE_CLIENTSECRET="@Microsoft.KeyVault(SecretUri=$clientSecretId)"
