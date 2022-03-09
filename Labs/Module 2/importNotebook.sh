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

# Extract the access_token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "Management Access Token: $mgmt_access_token"

pathOnDatabricks="/tpcds"
JSON="{ \"path\" : \"$pathOnDatabricks\" }"
echo "Creating Path: $JSON"

curl -X POST https://$workspaceUrl/api/2.0/workspace/mkdirs \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$JSON"

replaceSource="./"
replaceDest=""

find $dirPath -type f -name "notebook/*" -print0 | while IFS= read -r -d '' file; do
        echo "Processing file: $file"
        filename=${file//$replaceSource/$replaceDest}
        echo "New filename: $filename"

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

        echo "curl -F language=$language -F path=$notebookPathUnderWorkspace/$filename -F content=@$file https://$workspaceUrl/api/2.0/workspace/import"

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