#! /usr/bin/bash

# Get environment details
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)

# Key Vault Secret Info
KEY_VAULT="pockv-tpcds"
ARM_SPN_CREDENTIAL="tpcds-spn-secret"
ARM_SPN_OBJECT="tpcds-spn-object"
ARM_SPN_CLIENT="tpcds-spn-client"
ARM_SPN_TENANT="tpcds-spn-tenant"

# Databricks Configuration
MANAGEMENT_RESOURCE_ENDPOINT="https://management.core.windows.net/" 
RESOURCE_GROUP="PoC-Synapse-Analytics"
LOCATION="eastus"

echo "Creating Service Principal ......"

APP_SPN_NAME="pocapp-tpcds"
ARM_CLIENT_SECRET=$(az ad sp create-for-rbac --name "$APP_SPN_NAME" --scopes /subscriptions/"$ARM_SUBSCRIPTION_ID" --query password -o tsv)

ARM_TENANT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].appOwnerTenantId -o tsv)
ARM_CLIENT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].appId -o tsv)
ARM_OBJECT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].objectId -o tsv)

echo "Creating Key Vault ......"

if [[ $(az keyvault list --resource-group $RESOURCE_GROUP | jq .[].name | grep -w $KEY_VAULT) != $KEY_VAULT ]]; then
    az keyvault create --name $KEY_VAULT --resource-group $RESOURCE_GROUP --location $LOCATION
fi

az keyvault secret set  --name $ARM_SPN_CREDENTIAL --value $ARM_CLIENT_SECRET --vault-name $KEY_VAULT

az keyvault secret set --name $ARM_SPN_OBJECT --value $ARM_OBJECT_ID --vault-name $KEY_VAULT

az keyvault secret set --name $ARM_SPN_CLIENT --value $ARM_CLIENT_ID --vault-name $KEY_VAULT

az keyvault secret set --name $ARM_SPN_TENANT --value $ARM_TENANT_ID --vault-name $KEY_VAULT

echo "ARM_OBJECT_ID : $ARM_OBJECT_ID"
echo "$(az keyvault secret show --name $ARM_SPN_OBJECT --vault-name $KEY_VAULT --query value -o tsv)"

echo "ARM_CLIENT_ID : $ARM_CLIENT_ID"
echo "$(az keyvault secret show --name $ARM_SPN_CLIENT --vault-name $KEY_VAULT --query value -o tsv)"

echo "ARM_TENANT_ID : $ARM_TENANT_ID"
echo "$(az keyvault secret show --name $ARM_SPN_TENANT --vault-name $KEY_VAULT --query value -o tsv)"

echo "ARM_CLIENT_SECRET : $ARM_CLIENT_SECRET"
echo "$(az keyvault secret show --name $ARM_SPN_CREDENTIAL --vault-name $KEY_VAULT --query value -o tsv)"

echo "Assign the Resource Group Contributor Role to SPN"
az role assignment create --assignee "$ARM_OBJECT_ID" \
--role "Contributor" \
--scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

echo "complete initialization ......."

