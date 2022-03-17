#! /usr/bin/bash

######################################################################################
# Get Environment Details
######################################################################################
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)

######################################################################################
# Key Vault Secret Info
######################################################################################
#KEY_VAULT="sw-pockv-tpcds-app"
KEY_VAULT=$(terraform output -state=Terraform/terraform.tfstate -raw key_vault_name 2>&1)
echo "Using Key Vault: ${KEY_VAULT}"
ARM_SPN_CREDENTIAL="tpcds-spn-secret"
ARM_SPN_OBJECT="tpcds-spn-object"
ARM_SPN_CLIENT="tpcds-spn-client"
ARM_SPN_TENANT="tpcds-spn-tenant"

######################################################################################
# Synapse Configuration
######################################################################################
SYNAPSE_RESOURCE="https://dev.azuresynapse.net/"
#SYNAPSE_WORKSPACE="pocsynapseanalytics-tpcds"
SYNAPSE_WORKSPACE=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
SYNAPSE_END_POINT="${SYNAPSE_WORKSPACE}.dev.azuresynapse.net"
SYNAPSE_SQL_POOL="DataWarehouse"
SYNAPSE_PIPELINE_NAME="LoadTPCDS"

######################################################################################
# Get Service Principal Info
######################################################################################
echo "Retrieving Service Principal Info ......"
APP_SPN_NAME="sw-pocapp-tpcds"

ARM_OBJECT_ID=$(az keyvault secret show --name $ARM_SPN_OBJECT --vault-name $KEY_VAULT --query value -o tsv)
ARM_CLIENT_ID=$(az keyvault secret show --name $ARM_SPN_CLIENT --vault-name $KEY_VAULT --query value -o tsv)
ARM_TENANT_ID=$(az keyvault secret show --name $ARM_SPN_TENANT --vault-name $KEY_VAULT --query value -o tsv)
ARM_CLIENT_SECRET=$(az keyvault secret show --name $ARM_SPN_CREDENTIAL --vault-name $KEY_VAULT --query value -o tsv)

set -s  $ARM_SUBSCRIPTION_ID

######################################################################################
# Get access tokens for Synapse Analytic API
######################################################################################
token=$(curl -X POST https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/token \
  -F resource=$SYNAPSE_RESOURCE \
  -F client_id=$ARM_CLIENT_ID \
  -F grant_type=client_credentials \
  -F client_secret=$ARM_CLIENT_SECRET | jq .access_token --raw-output) 

echo $token

######################################################################################
# Create Pipeline Run
######################################################################################
pipelineJson="{ \"DatabaseName\" : \"$SYNAPSE_SQL_POOL\" }"

responsePipeline=$(curl -X POST https://$SYNAPSE_END_POINT/pipelines/${SYNAPSE_PIPELINE_NAME}/createRun?api-version=2020-12-01 \
    -H "Authorization:Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$pipelineJson")

echo $responsePipeline
