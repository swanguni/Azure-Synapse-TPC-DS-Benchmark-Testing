#! /usr/bin/bash

######################################################################################
# Get Environment Details
######################################################################################
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)
## Databricks APP ID (DON'T CHANGE)
export AZURE_DATABRICKS_APP_ID="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" 

######################################################################################
# Key Vault Secret Info
######################################################################################
#KEY_VAULT="pockv-tpcds-app"
KEY_VAULT=$(terraform output -state=Terraform/terraform.tfstate -raw key_vault_name 2>&1)
echo "Using Key Vault: ${KEY_VAULT}"
ARM_SPN_CREDENTIAL="tpcds-spn-secret"
ARM_SPN_OBJECT="tpcds-spn-object"
ARM_SPN_CLIENT="tpcds-spn-client"
ARM_SPN_TENANT="tpcds-spn-tenant"

######################################################################################
# Storage Account Info
######################################################################################
STORAGE_ACCT=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_name 2>&1)
echo "Using Azure Storage Account: ${STORAGE_ACCT}"
#STORAGE_ACCT="tpcdsacctpoc"
FILE_SYSTEM_NAME="data"

######################################################################################
# Databricks Configuration
######################################################################################
MANAGEMENT_RESOURCE_ENDPOINT="https://management.core.windows.net/" 
#RESOURCE_GROUP="PoC-Synapse-Analytics"
RESOURCE_GROUP=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
echo "Using Resource Group: ${RESOURCE_GROUP}"
#LOCATION="eastus"
LOCATION=$(terraform output -state=Terraform/terraform.tfstate -raw region_name 2>&1)
echo "Using Region: ${LOCATION}"
DATABRICKS_WORKSPACE=$(terraform output -state=Terraform/terraform.tfstate -raw databricks_workspace_name 2>&1)
echo "Using Databricks workspace: ${DATABRICKS_WORKSPACE}"
#DATABRICKS_WORKSPACE="pocdatabricks-tpcds"
DATABRICKS_CLUSTER_NAME="tpc-ds-cluster"
DATABRICKS_SPARK_VERSION="9.1.x-scala2.12"
DATABRICKS_NODE_TYPE="Standard_D3_v2"
DATABRICKS_NUM_WORKERS=4 
DATABRICKS_SPARK_CONF='{"spark.speculation":"true","spark.databricks.delta.preview.enabled":"true"}'
DATABRICKS_AUTO_TERMINATE_MINUTES=60
DATABRICKS_INIT_SCRIPT='[ { "dbfs": { "destination": "dbfs:/databricks/scripts/tpcds-install.sh" } } ]'
DATABRICKS_CLUSTER_LOG='{ "dbfs": { "destination": "dbfs:/cluster-logs" } } '
DATABRICKS_SPARK_LIBRARY='[ { "jar": "dbfs:/databricks/jars/spark-sql-perf_2.12-0.5.1-SNAPSHOT.jar" } ]'
DATABRICKS_CLUSTER_ID="tpcds-db-cluster-id"

initScriptsPath="dbfs:/databricks/scripts"
libraryPath="dbfs:/databricks/jars"
pathOnDatabricks="/tpcds"
notebookName="/tpcds/TPC-DS-Data-Generation.scala"
initScriptName="tpcds-install.sh"
libraryJar="spark-sql-perf_2.12-0.5.1-SNAPSHOT.jar"

######################################################################################
# Get Service Principal Info
######################################################################################
echo "Retrieving Service Principal Info ......"
APP_SPN_NAME="pocapp-tpcds"

ARM_OBJECT_ID=$(az keyvault secret show --name $ARM_SPN_OBJECT --vault-name $KEY_VAULT --query value -o tsv)
ARM_CLIENT_ID=$(az keyvault secret show --name $ARM_SPN_CLIENT --vault-name $KEY_VAULT --query value -o tsv)
ARM_TENANT_ID=$(az keyvault secret show --name $ARM_SPN_TENANT --vault-name $KEY_VAULT --query value -o tsv)
ARM_CLIENT_SECRET=$(az keyvault secret show --name $ARM_SPN_CREDENTIAL --vault-name $KEY_VAULT --query value -o tsv)

######################################################################################
# Get Notebook Info
######################################################################################
fileFormat="parquet" 
mountPoint="data"
scaleFactor=1

######################################################################################
# Login using Databricks App Service Principal
######################################################################################
# echo "Logging in using Azure Service Pricipal ..... "
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account set -s  $ARM_SUBSCRIPTION_ID

######################################################################################
# Get workspace id in the given resource group 
# 	e.g. /subscriptions/(subscription_id)/resourceGroups/(rg)/providers/Microsoft.Databricks/workspaces/(databricks_workspace)
# Get Databricks workspace URL 
#	e.g. adb-xxxxxxxxxxxxxxxx.x.azuredatabricks.net
######################################################################################
workspaceId=$(az resource show --resource-type Microsoft.Databricks/workspaces -g $RESOURCE_GROUP -n "$DATABRICKS_WORKSPACE" --query id -o tsv)
echo "Workspce ID: $workspaceId"

workspaceUrl=$(az resource show --resource-type Microsoft.Databricks/workspaces -g "$RESOURCE_GROUP" -n "$DATABRICKS_WORKSPACE" --query properties.workspaceUrl --output tsv)
echo "Workspce URL: $workspaceUrl"

######################################################################################
# Get access tokens for Databricks API 
######################################################################################
token_response=$(az account get-access-token --resource $AZURE_DATABRICKS_APP_ID -o json)

token=$(jq .accessToken -r <<< "$token_response")
echo "API Token: $token"

# Get the Azure Management Resource endpoint token
az_mgmt_resource_endpoint=$(curl -X GET \
				    -H 'Content-Type: application/x-www-form-urlencoded' \
				    -d 'grant_type=client_credentials&client_id='$ARM_CLIENT_ID'&resource='$MANAGEMENT_RESOURCE_ENDPOINT'&client_secret='$ARM_CLIENT_SECRET \
				     https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/token)

# Extract management access token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "Management Access Token: $mgmt_access_token"

######################################################################################
# Create directory for Library Jars
######################################################################################
libraryPathJson="{ \"path\" : \"$libraryPath\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/mkdirs -d $libraryPathJson"

curl -X POST https://$workspaceUrl/api/2.0/dbfs/mkdirs \
    -H "Authorization:Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    -H "Content-Type: application/json" \
    --data "$libraryPathJson"

######################################################################################
# Upload library jars
######################################################################################
replaceSource="./"
replaceDest=""

find . -type f -name "$libraryJar" -print0 | while IFS= read -r -d '' file; do
    echo ""
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    echo "curl -F path=$libraryPath/$filename -F content=@$filename https://$workspaceUrl/api/2.0/dbfs/put"

    curl -n https://$workspaceUrl/api/2.0/dbfs/put \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -F overwrite=true \
        -F path="$libraryPath/$filename" \
        -F content=@"$filename"       

    echo ""

done

######################################################################################
# List library jars
######################################################################################
echo "curl https://$workspaceUrl/api/2.0/dbfs/list -d $libraryPathJson"

curl -X GET https://$workspaceUrl/api/2.0/dbfs/list \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$libraryPathJson"
echo ""
echo "Complete uploading library jar ......"

######################################################################################
# Create directory for Init Scripts
######################################################################################
initScriptJson="{ \"path\" : \"$initScriptsPath\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/mkdirs -d $initScriptJson"

curl -X POST https://$workspaceUrl/api/2.0/dbfs/mkdirs \
    -H "Authorization:Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    -H "Content-Type: application/json" \
    --data "$initScriptJson"

######################################################################################
# Upload Init Scripts
######################################################################################
replaceSource="./"
replaceDest=""

find . -type f -name "$initScriptName" -print0 | while IFS= read -r -d '' file; do
    echo ""
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    echo "curl -F path=$initScriptsPath/$filename -F content=@$filename https://$workspaceUrl/api/2.0/dbfs/put"

    curl -n https://$workspaceUrl/api/2.0/dbfs/put \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -F overwrite=true \
        -F path="$initScriptsPath/$filename" \
        -F content=@"$filename"       

    echo ""

done

######################################################################################
# List Init Scripts 
######################################################################################
echo "curl https://$workspaceUrl/api/2.0/dbfs/list -d $initScriptJson"

curl -X GET https://$workspaceUrl/api/2.0/dbfs/list \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$initScriptJson"

echo ""
echo "Complete uploading init script ......"

######################################################################################
# Import Notebook into workspace
######################################################################################
notebookPathJson="{ \"path\" : \"$pathOnDatabricks\" }"   
echo "curl https://$workspaceUrl/api/2.0/workspace/mkdirs --data $notebookPathJson"
echo ""

curl -X POST https://$workspaceUrl/api/2.0/workspace/mkdirs \
        -H "Authorization:Bearer $token" \
        -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$notebookPathJson"

replaceSource="./data_generation/"
replaceDest=""

# Locate the directory for the databricks artifacts 
find . -type d -name "data_generation" -print0 | while IFS= read -r -d '' dirPath; do
    echo "Processing directory: $dirPath"
done

find $dirPath -type f -name "TPC-DS-Data-Generation*" -print0 | while IFS= read -r -d '' file; do
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

        echo "curl -F language=$language -F path=$pathOnDatabricks/$filename -F content=@$file https://$workspaceUrl/api/2.0/workspace/import"

        curl -n https://$workspaceUrl/api/2.0/workspace/import \
            -H "Authorization:Bearer $token" \
            -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
            -F language="$language" \
            -F overwrite=true \
            -F path="$pathOnDatabricks/$filename" \
            -F content=@"$file"       
    done

echo ""
echo "Complete importing the notebook into workspace ......."

######################################################################################
# Create Databricks Cluster
# Reference: https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/
######################################################################################
clusterConfigJson=$( jq -n -c \
                --arg cn "$DATABRICKS_CLUSTER_NAME" \
                --arg sv "$DATABRICKS_SPARK_VERSION" \
                --arg nt "$DATABRICKS_NODE_TYPE" \
                --arg nw "$DATABRICKS_NUM_WORKERS" \
                --arg sc "$DATABRICKS_SPARK_CONF" \
                --arg at "$DATABRICKS_AUTO_TERMINATE_MINUTES" \
                --arg cl "$DATABRICKS_CLUSTER_LOG" \
                --arg is "$DATABRICKS_INIT_SCRIPT" \
                '{cluster_name: $cn,
                spark_version: $sv,
                node_type_id: $nt,
                num_workers: ($nw|tonumber),
                autotermination_minutes: ($at|tonumber),
                spark_conf: ($sc|fromjson),
		    cluster_log_conf: ($cl|fromjson),
 		    init_scripts: ($is|fromjson)}')

echo "Creating Databricks Cluster ........" 
echo "Databricks Cluster Configuration : $clusterConfigJson"

cluster_id_response=$(curl -X POST \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
    -d $clusterConfigJson \
    https://$workspaceUrl/api/2.0/clusters/create)

clusterId=$(jq .cluster_id -r <<< "$cluster_id_response")
echo "Cluster id: $clusterId"

######################################################################################
# Check to see if the cluster creation is complete
######################################################################################
echo "Waiting for the cluster creation to be complete ......"
clusterJson="{ \"cluster_id\" : \"$clusterId\" }"
state="RUNNING"

replaceSource="\""
replaceDest=""

while :
	do
	clusterResponse=$(curl -X GET https://$workspaceUrl/api/2.0/clusters/get \
      	  -H "Authorization:Bearer $token" \
	  	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
              -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
              -H "Content-Type: application/json" \
              --data "$clusterJson")
      echo $clusterResponse

      rClusterId=$(jq .cluster_id <<< $clusterResponse)
      dClusterId=${rClusterId//$replaceSource/$replaceDest}
      
      rState=$(jq .state<<< $clusterResponse)
      dState=${rState//$replaceSource/$replaceDest}
      
	echo "$dClusterId status : $dState"

	if [[ "$dClusterId" == "$clusterId" && "$dState" == "$state" ]] ; then
            echo "$dClusterId status : $dState"
		break	
	fi

	sleep 15
done

echo "Cluster creation is complete ......"

######################################################################################
# Install Spark Perf Library
######################################################################################
perfLibraryJson=$( jq -n -c --arg ci "$clusterId" --arg sl "$DATABRICKS_SPARK_LIBRARY" \
                '{cluster_id: $ci,
 		      libraries: ($sl|fromjson)}')

echo "Databricks Library Config : $perfLibraryJson"

libraryResponse=$(curl -X POST https://$workspaceUrl/api/2.0/libraries/install \
        -H "Authorization:Bearer $token" \
	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$perfLibraryJson")

echo $libraryResponse

######################################################################################
# Check to see if the library installation is complete
######################################################################################
echo "Waiting for the installtion of the spark perf library ......" 

clusterStatusJson="{ \"cluster_id\" : \"$clusterId\" }"
jarName="\"dbfs:/databricks/jars/spark-sql-perf_2.12-0.5.1-SNAPSHOT.jar"\"
installed="\"INSTALLED"\"

while :
	do
	clusterStatusResponse=$(curl -X GET https://$workspaceUrl/api/2.0/libraries/cluster-status \
      	  -H "Authorization:Bearer $token" \
	  	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
              -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
              -H "Content-Type: application/json" \
              --data "$clusterStatusJson")
      echo $clusterStatusResponse
      echo "Library Installation Status : $(jq .library_statuses[].status <<< $clusterStatusResponse)"

	if [[ "$(jq .library_statuses[].status <<< $clusterStatusResponse)" == "$installed" && "$(jq .library_statuses[].library.jar <<< $clusterStatusResponse)" == "$jarName" ]] ; then
            echo "$jarName status : $installed"
		break	
	fi

	sleep 15
done


######################################################################################
# Restart the clsuer after installation of the Spark library 
######################################################################################
echo "Restart the clsuer after installation of the Spark library ......"
clusterJson="{ \"cluster_id\" : \"$clusterId\" }"
state="RUNNING"

replaceSource="\""
replaceDest=""

curl -X POST https://$workspaceUrl/api/2.0/clusters/restart \
      	  -H "Authorization:Bearer $token" \
	  	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
              -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
              -H "Content-Type: application/json" \
              --data "$clusterJson"

######################################################################################
# Check to see if the cluster restart is complete
######################################################################################
echo "Waiting to restart the clsuer after installation of the Spark library ......"

while :
	do
	clusterResponse=$(curl -X GET https://$workspaceUrl/api/2.0/clusters/get \
      	  -H "Authorization:Bearer $token" \
	  	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
              -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
              -H "Content-Type: application/json" \
              --data "$clusterJson")
      echo $clusterResponse

      rClusterId=$(jq .cluster_id <<< $clusterResponse)
      dClusterId=${rClusterId//$replaceSource/$replaceDest}
      
      rState=$(jq .state<<< $clusterResponse)
      dState=${rState//$replaceSource/$replaceDest}
      
	echo "$dClusterId status : $dState"

	if [[ "$dClusterId" == "$clusterId" && "$dState" == "$state" ]] ; then
            echo "$dClusterId status : $dState"
		break	
	fi

	sleep 15
done

######################################################################################
# Submit Config Notebook 
######################################################################################
baseParametersJson=$( jq -n -c --arg ci "$ARM_CLIENT_ID" \
                                --arg cs "$ARM_CLIENT_SECRET" \
                                --arg ti "$ARM_TENANT_ID" \
                                --arg sc "$STORAGE_ACCT" \
                                --arg sn "$FILE_SYSTEM_NAME" \
                                --arg ff "$fileFormat" \
                                --arg mp "$mountPoint" \
                                --arg sf "$scaleFactor" \
                                '{clientId: $ci, 
                                clientSecret: $cs, 
                                tenantId: $ti, 
                                storageAccountName: $sc, 
                                fileSystemName: $sn, 
                                fileFormat: $ff, 
                                mountPoint: $mp, 
                                scaleFactor: ($sf|tonumber)}')

notebookTaskJson=$( jq -n -c \
                		--arg nn "$notebookName" \
                		--arg bj "$baseParametersJson" \
                		'{notebook_path: $nn,
                  	  base_parameters: ($bj|fromjson)}')

notebookPayloadJson=$( jq -n -c \
                --arg rn "TPC DS Data Generation" \
                --arg ci "$clusterId" \
                --arg nt "$notebookTaskJson" \
                '{run_name: $rn,
                  existing_cluster_id: $ci,
 		      notebook_task: ($nt|fromjson)}')

echo "Running Notebook $notebookName........" 
echo "Databricks Cluster Configuration : $notebookPayloadJson"

runNotebookResponse=$(curl -X POST https://$workspaceUrl/api/2.0/jobs/runs/submit \
        -H "Authorization:Bearer $token" \
	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
        -H "Content-Type: application/json" \
        --data "$notebookPayloadJson")

runId=$(jq .run_id -r <<< "$runNotebookResponse")
echo "runId: $runId"

######################################################################################
# Waiting the TPC DS Data Generation Job to complete 
######################################################################################
echo "Waiting the TPC DS Data Generation Job to complete ......"
jobsJson="{ \"run_id\" : \"$runId\" }"
state="TERMINATED"

replaceSource="\""
replaceDest=""

while :
	do
	jobStatusResponse=$(curl -X GET https://$workspaceUrl/api/2.0/jobs/runs/get \
      	  -H "Authorization:Bearer $token" \
	  	  -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" \
              -H "X-Databricks-Azure-Workspace-Resource-Id: $workspaceId" \
              -H "Content-Type: application/json" \
              --data "$jobsJson")
      echo $jobStatusResponse

      rRunId=$(jq .run_id <<< $jobStatusResponse)
      dRunId=${rRunId//$replaceSource/$replaceDest}

      rState=$(jq .state<<< $jobStatusResponse)
      dState=${rState//$replaceSource/$replaceDest}
	echo "$dRunId status : $dState"

      lcState=$(jq .state.life_cycle_state<<< $jobStatusResponse)
      dlcState=${lcState//$replaceSource/$replaceDest}

      resState=$(jq .state.result_state<<< $jobStatusResponse)
      dresState=${resState//$replaceSource/$replaceDest}

	if [[ "$dRunId" == "$runId" && "$dlcState" == "$state" ]] ; then
            echo "$runId status : $dlcState"
		break	
	fi

	sleep 10
done

echo "TPC DS Job Status : $dresState, check further details on databricks logs and storage account for the dataset generated ......"
