#!/bin/bash

AZURE_BACKUP_RESOURCE_GROUP=rg-gms-velero-poc-tools
az group create -n $AZURE_BACKUP_RESOURCE_GROUP --location EastUS

# Create the storage account
#AZURE_STORAGE_ACCOUNT_ID="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
AZURE_STORAGE_ACCOUNT_ID="sa-gms-velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
az storage account create \
    --name $AZURE_STORAGE_ACCOUNT_ID \
    --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

az storage container create -n velero --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID

AZURE_SUBSCRIPTION_ID=`az account list --query '[?isDefault].id' -o tsv`
AZURE_TENANT_ID=`az account list --query '[?isDefault].tenantId' -o tsv`

AZURE_STORAGE_ACCOUNT_ACCESS_KEY=`az storage account keys list --account-name $AZURE_STORAGE_ACCOUNT_ID --query "[?keyName == 'key1'].value" -o tsv`

echo AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID} >> ./credentials-velero.txt
echo AZURE_TENANT_ID=${AZURE_TENANT_ID}  >> ./credentials-velero.txt
echo AZURE_RESOURCE_GROUP=${AZURE_BACKUP_RESOURCE_GROUP}  >> ./credentials-velero.txt
echo AZURE_CLOUD_NAME=AzurePublicCloud  >> ./credentials-velero.txt

