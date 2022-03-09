#! /usr/bin/bash

# Get environment details
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)
export AZURE_DATABRICKS_APP_ID="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"

echo "Creating Service Principal for Databricks "

DATABRICKS_SPN_NAME="App-PoC-TPCDS-Databricks"
# ARM_CLIENT_SECRET=$(az ad sp create-for-rbac --name "$DATABRICKS_SPN_NAME" --scopes /subscriptions/"$ARM_SUBSCRIPTION_ID" --query password -o tsv)
ARM_CLIENT_SECRET="iwk.rdo1T1o1lJIowbKEI5C25edsG6yqOG"

ARM_TENANT_ID=$(az ad sp list --display-name "$DATABRICKS_SPN_NAME" --query [].appOwnerTenantId -o tsv)
ARM_CLIENT_ID=$(az ad sp list --display-name "$DATABRICKS_SPN_NAME" --query [].appId -o tsv)
ARM_OBJECT_ID=$(az ad sp list --display-name "$DATABRICKS_SPN_NAME" --query [].objectId -o tsv)

MANAGEMENT_RESOURCE_ENDPOINT="https://management.core.windows.net/" 
RESOURCE_GROUP="PoC-Synapse-Analytics"
LOCATION="eastus"
DATABRICKS_WORKSPACE="pocdatabricks-tpcds"
DATABRICKS_CLUSTER_NAME="test-cluster-01"
DATABRICKS_SPARK_VERSION="10.0-scala2.12"
DATABRICKS_NODE_TYPE="Standard_D3_v2"
DATABRICKS_NUM_WORKERS=4 
DATABRICKS_SPARK_CONF='{"spark.speculation":"true","spark.databricks.delta.preview.enabled":"true"}'
DATABRICKS_AUTO_TERMINATE_MINUTES=60

echo "Assign the Contributor Role to SPN"
az role assignment create --assignee "$ARM_OBJECT_ID" \
--role "Contributor" \
--scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Login using service principle
echo "Logging in using Azure Service Pricipal ..... "
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

az account set -s  $ARM_SUBSCRIPTION_ID

# Create Resource Group if not exists
if [[ $(az group exists --resource-group $RESOURCE_GROUP) = "false" ]]; then
    echo "Resource Group does not exists, so creating.."
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# Enable install of extensions without prompt
az config set extension.use_dynamic_install=yes_without_prompt

echo "Creating Databricks Workspace ........" 

# Create databricks workspace using extenstion
# The extension will automatically install the first time you run an az databricks workspace command
# Ref: https://docs.microsoft.com/en-us/cli/azure/ext/databricks/databricks?view=azure-cli-latest

if [[ $(az databricks workspace list | jq .[].name | grep -w $DATABRICKS_WORKSPACE) != $DATABRICKS_WORKSPACE ]]; then
    az databricks workspace create \
        --location $LOCATION \
        --name $DATABRICKS_WORKSPACE \
        --sku standard \
        --resource-group $RESOURCE_GROUP \
        --enable-no-public-ip 
fi

# Get workspace id in the given resource group 
# e.g. /subscriptions/(subscription_id)/resourceGroups/(rg)/providers/Microsoft.Databricks/workspaces/(databricks_workspace)
workspaceId=$(az resource show --resource-type Microsoft.Databricks/workspaces -g $RESOURCE_GROUP -n "$DATABRICKS_WORKSPACE" --query id -o tsv)
echo "Workspce ID: $workspaceId"

# Get workspace url e.g. adb-xxxxxxxxxxxxxxxx.x.azuredatabricks.net
workspaceUrl=$(az resource show --resource-type Microsoft.Databricks/workspaces -g "$RESOURCE_GROUP" -n "$DATABRICKS_WORKSPACE" --query properties.workspaceUrl --output tsv)
echo "Workspce URL: $workspaceUrl"

# token response for the azure databricks app 
token_response=$(az account get-access-token --resource $AZURE_DATABRICKS_APP_ID)

# Extract accessToken value
token=$(jq .accessToken -r <<< "$token_response")
echo "App Token: $token"

# Get the Azure Management Resource endpoint token
# https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token
az_mgmt_resource_endpoint=$(curl -X GET -H 'Content-Type: application/x-www-form-urlencoded' \
-d 'grant_type=client_credentials&client_id='$ARM_CLIENT_ID'&resource='$MANAGEMENT_RESOURCE_ENDPOINT'&client_secret='$ARM_CLIENT_SECRET \
https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/token)

# Extract the access_token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "Management Access Token: $mgmt_access_token"

# Create PAT token valid for 5 min (300 sec)
pat_token_response=$(curl -X POST \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $wsId" \
    -d '{"lifetime_seconds": 300,"comment": "PAT token"}' \
    https://$workspaceUrl/api/2.0/token/create
)

# Print PAT token
pat_token=$(jq .token_value -r <<< "$pat_token_response")
echo "pat_token: $pat_token"

# List PAT tokens (OPTIONAL)
curl -X GET \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    https://$workspaceUrl/api/2.0/token/list

# List current clusters (OPTIONAL) and could be used to determine the next command e.g. create,restart,terminate etc
curl -X GET \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    https://$workspaceUrl/api/2.0/clusters/list

# Create Cluster config from variables 
JSON_STRING=$( jq -n -c \
                --arg cn "$DATABRICKS_CLUSTER_NAME" \
                --arg sv "$DATABRICKS_SPARK_VERSION" \
                --arg nt "$DATABRICKS_NODE_TYPE" \
                --arg nw "$DATABRICKS_NUM_WORKERS" \
                --arg sc "$DATABRICKS_SPARK_CONF" \
                --arg at "$DATABRICKS_AUTO_TERMINATE_MINUTES" \
                '{cluster_name: $cn,
                spark_version: $sv,
                node_type_id: $nt,
                num_workers: ($nw|tonumber),
                autotermination_minutes: ($at|tonumber),
                spark_conf: ($sc|fromjson)}' )

echo "Creating cluster ........" 

# Create a new Cluster
# Reference: https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/
cluster_id_response=$(curl -X POST \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    -d $JSON_STRING \
    https://$workspaceUrl/api/2.0/clusters/create)

clusterId=$(jq .cluster_id -r <<< "$cluster_id_response")
echo "Cluster id: $clusterId"