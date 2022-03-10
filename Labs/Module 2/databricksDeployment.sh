#! /usr/bin/bash

# Get environment details
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)
export AZURE_DATABRICKS_APP_ID="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" 

# Key Vault Secret Info
KEY_VAULT="tpcds-poc-kv"
ARM_SPN_CREDENTIAL="tpcds-spn-secret"
ARM_SPN_OBJECT="tpcds-spn-object"
ARM_SPN_CLIENT="tpcds-spn-client"
ARM_SPN_TENANT="tpcds-spn-tenant"

# Databricks Configuration
MANAGEMENT_RESOURCE_ENDPOINT="https://management.core.windows.net/" 
RESOURCE_GROUP="PoC-Synapse-Analytics"
LOCATION="eastus"
DATABRICKS_WORKSPACE="pocdatabricks-tpcds"
DATABRICKS_CLUSTER_NAME="tpc-ds-cluster"
DATABRICKS_SPARK_VERSION="9.1.x-scala2.12"
DATABRICKS_NODE_TYPE="Standard_D3_v2"
DATABRICKS_NUM_WORKERS=4 
DATABRICKS_SPARK_CONF='{"spark.speculation":"true","spark.databricks.delta.preview.enabled":"true"}'
DATABRICKS_AUTO_TERMINATE_MINUTES=60
DATABRICKS_CLUSTER_ID="tpcds-db-cluster-id"

echo "Creating Service Principal ......"

APP_SPN_NAME="App-PoC-TPCDS-Test"
ARM_CLIENT_SECRET=$(az ad sp create-for-rbac --name "$APP_SPN_NAME" --scopes /subscriptions/"$ARM_SUBSCRIPTION_ID" --query password -o tsv)
#ARM_CLIENT_SECRET="iwk.rdo1T1o1lJIowbKEI5C25edsG6yqOG"

ARM_TENANT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].appOwnerTenantId -o tsv)
ARM_CLIENT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].appId -o tsv)
ARM_OBJECT_ID=$(az ad sp list --display-name "$APP_SPN_NAME" --query [].objectId -o tsv)

echo "Creating Key Vault ......"

if [[ $(az keyvault list --resource-group $RESOURCE_GROUP | jq .[].name | grep -w $KEY_VAULT) != $KEY_VAULT ]]; then
    az keyvault create --name $KEY_VAULT --resource-group $RESOURCE_GROUP --location $LOCATION
fi

echo "ARM_CLIENT_SECRET : $ARM_CLIENT_SECRET"

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

# Login using service principle
echo "Logging in using Azure Service Pricipal ..... "
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

az account set -s  $ARM_SUBSCRIPTION_ID

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

# Extract management access token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "Management Access Token: $mgmt_access_token"

# Import Notebook into workspace
pathOnDatabricks="/tpcds"

JSON="{ \"path\" : \"$pathOnDatabricks\" }"
echo "Creating Path: $JSON"    
echo "curl https://$workspaceUrl/api/2.0/workspace/mkdirs --data $JSON"

curl -X POST https://$workspaceUrl/api/2.0/workspace/mkdirs \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$JSON"

replaceSource="./data_generation"
replaceDest=""

# Locate the directory for the databricks artifacts 
find . -type d -name "data_generation" -print0 | while IFS= read -r -d '' dirPath; do
    echo "Processing directory: $dirPath"
done

find $dirPath -type f -name "*DS*" -print0 | while IFS= read -r -d '' file; do
        echo "Processing file: $file"
        filename=${file//$replaceSource/$replaceDest}
        # echo "New filename: $filename"

        language=""
        if [[ "$filename" == *sql ]]
        then
            language="SQL"
        fi

        if [[ "$filename" == *scala ]]
        then
            language="SCALA"
        fi

        if [[ "$filename" == *py ]]
        then
            language="PYTHON"
        fi

        if [[ "$filename" == *r ]]
        then
            language="R"
        fi

        echo "curl -F language=$language -F path=$pathOnDatabricks/$filename -F content=@$file https://$workspaceUrl/api/2.0/workspace/import"

        curl -n https://$workspaceUrl/api/2.0/workspace/import \
            -H "Authorization:Bearer $token" \
            -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
            -F language="$language" \
            -F overwrite=true \
            -F path="$pathOnDatabricks/$filename" \
            -F content=@"$file"       

        echo ""

    done

# Create Databricks Cluster Config 
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

echo "Creating Databricks Cluster ........" 

# Create a new Cluster
# Reference: https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/
cluster_id_response=$(curl -X POST \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    -d $JSON_STRING \
    https://$workspaceUrl/api/2.0/clusters/create)

clusterId=$(jq .cluster_id -r <<< "$cluster_id_response")
az keyvault secret set --name $DATABRICKS_CLUSTER_ID --value $clusterId --vault-name $KEY_VAULT
echo "Cluster id: $clusterId"