AZURE_BACKUP_RESOURCE_GROUP=rg-gms-velero-poc-tools
az group create -n $AZURE_BACKUP_RESOURCE_GROUP --location EastUS

# Create the storage account
AZURE_STORAGE_ACCOUNT_ID="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
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

az role definition create --role-definition azure-role.json

$AZURE_CLIENT_SECRET=(az ad sp create-for-rbac --name "velero" --role "velero-custom-role" --query 'password' -o tsv --scopes  /subscriptions/$AZURE_SUBSCRIPTION_ID)
#$AZURE_CLIENT_SECRET=(az ad sp create-for-rbac --name "velero" --role "Contributor" --query 'password' -o tsv --scopes  /subscriptions/$AZURE_SUBSCRIPTION_ID)

$AZURE_CLIENT_ID=(az ad sp list --display-name "velero" --query '[0].appId' -o tsv)

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${AZURE_BACKUP_RESOURCE_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud" | Out-File -FilePath ./credentials-velero.txt
