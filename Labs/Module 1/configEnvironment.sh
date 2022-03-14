#!/bin/bash
###################################################################################################################
# This is the script for the Post-Deployment Configuration including 
#	- Pipeline, SQL Pool, Serverless SQL
#	- Service Principal, Key Vault 
#     - RBAC roles assignment
#
# This script should be executed via the Azure Cloud Shell via:
#
# @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 1$ bash configEnvironment.sh
#
###################################################################################################################

azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)

###################################################################################################################
# 	 
# Get the output variables from the Terraform deployment
#       
###################################################################################################################

resourceGroup=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
synapseAnalyticsWorkspaceName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
synapseAnalyticsSQLPoolName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_pool_name 2>&1)
synapseAnalyticsSQLAdmin=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login 2>&1)
synapseAnalyticsSQLAdminPassword=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login_password 2>&1)
datalakeName=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_name 2>&1)
privateEndpointsEnabled=$(terraform output -state=Terraform/terraform.tfstate -raw private_endpoints_enabled 2>&1)
region=$(terraform output -state=Terraform/terraform.tfstate -raw region_name 2>&1)
keyVaultName=$(terraform output -state=Terraform/terraform.tfstate -raw key_vault_name 2>&1)

echo "Azure Subscription: ${azureSubscriptionName}" 
echo "Azure Subscription ID: ${azureSubscriptionID}" 
echo "Azure AD Username: ${azureUsername}" 
echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}" 
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}" 
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}" 
echo "Data Lake Name: ${datalakeName}" 
echo "Region: ${region}" 
echo "Key Vault Name: ${keyVaultName}" 

###################################################################################################################
# 	 
# Config Synapse Analytics SQL Pool
#       
###################################################################################################################

# If Private Endpoints are enabled, temporarily disable the firewalls so we can copy files and perform additional configuration
if [ "$privateEndpointsEnabled" == "true" ]; then
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Allow >> configEnvironment.log 2>&1
    az synapse workspace firewall-rule create --name AllowAll --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255 >> configEnvironment.log 2>&1
    az synapse workspace firewall-rule create --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 >> configEnvironment.log 2>&1
fi

# Enable Result Set Cache
# echo "Enabling Result Set Caching..." | tee -a configEnvironment.log
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET RESULT_SET_CACHING ON;" >> configEnvironment.log 2>&1

# Enable the Query Store
# echo "Enabling the Query Store..." | tee -a configEnvironment.log
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET QUERY_STORE = ON;" >> configEnvironment.log 2>&1

###################################################################################################################
# 	 
# Config Synapse Analytics Pipeline, e.g. Auto Pause and Resume, Auto Loading
#       
###################################################################################################################

echo "Creating the Auto Pause and Resume pipeline..." | tee -a configEnvironment.log

# Copy the Auto_Pause_and_Resume Pipeline template and update the variables
cp artifacts/Auto_Pause_and_Resume.json.tmpl artifacts/Auto_Pause_and_Resume.json 2>&1
sed -i "s/REPLACE_SUBSCRIPTION/${azureSubscriptionID}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_RESOURCE_GROUP/${resourceGroup}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Auto_Pause_and_Resume.json

# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Auto Pause and Resume" --file @artifacts/Auto_Pause_and_Resume.json

# Create the Pause/Resume triggers in the Synapse Analytics Workspace
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Pause --file @artifacts/triggerPause.json
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Resume --file @artifacts/triggerResume.json

echo "Creating the Parquet Auto TPCDS Ingestion Pipeline..." | tee -a configEnvironment.log

# Create the Resource Class Logins
cp artifacts/Create_Resource_Class_Logins.sql.tmpl artifacts/Create_Resource_Class_Logins.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Resource_Class_Logins.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -i artifacts/Create_Resource_Class_Logins.sql

# Create the Resource Class Users
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Create_Resource_Class_Users.sql

# Create the Loading Users
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Create_Loading_User.sql

# Create the Schemas
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Create_Table_Schemas.sql

REPLACE_SERVER_NAME="${synapseAnalyticsWorkspaceName}".sql.azuresynapse.net
REPLACE_DB_NAME=${synapseAnalyticsSQLPoolName}

# Create the LS_Synapse_Managed_Identity Linked Service. This is primarily used for the Auto Ingestion pipeline.
cp artifacts/LS_Synapse_Managed_Identity.json.tmpl artifacts/LS_Synapse_Managed_Identity.json 2>&1
sed -i "s/REPLACE_SERVER_NAME/${REPLACE_SERVER_NAME}/g" artifacts/LS_Synapse_Managed_Identity.json
sed -i "s/REPLACE_DB_NAME/${REPLACE_DB_NAME}/g" artifacts/LS_Synapse_Managed_Identity.json
az synapse linked-service create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name LS_Synapse_Managed_Identity --file @artifacts/LS_Synapse_Managed_Identity.json

# Create the DS_Synapse_Managed_Identity Dataset. This is primarily used for the Auto Ingestion pipeline.
cp artifacts/DS_Synapse_Managed_Identity.json.tmpl artifacts/DS_Synapse_Managed_Identity.json 2>&1
sed -i "s/REPLACE_SERVER_NAME/${REPLACE_SERVER_NAME}/g" artifacts/DS_Synapse_Managed_Identity.json
sed -i "s/REPLACE_DB_NAME/${REPLACE_DB_NAME}/g" artifacts/DS_Synapse_Managed_Identity.json
az synapse dataset create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name DS_Synapse_Managed_Identity --file @artifacts/DS_Synapse_Managed_Identity.json

datalakeContainer1GB='raw\/tpc-ds\/source_files_001GB_parquet'
datalakeContainer1TB="raw\/tpc-ds\/source_files_001TB_parquet"

# Copy the Auto Ingestion Pipeline template and update the variables
cp artifacts/Load_TPC_DS.json.tmpl artifacts/Load_TPC_DS.json 2>&1
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Load_TPC_DS.json
sed -i -r "s/REPLACE_LOCATION/${datalakeContainer1GB}/g" artifacts/Load_TPC_DS.json

# Create the Auto Ingestion Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Load TPCDS" --file @artifacts/Load_TPC_DS.json >> configEnvironment.log 2>&1

###################################################################################################################
# 	 
# Config Synapse SQL Serverless 
#       
###################################################################################################################

echo "Creating the TPCDSDemo Data database using Synapse Serverless SQL..." | tee -a configEnvironment.log

# Create a Demo Data database using Synapse Serverless SQL
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -i artifacts/Create_Serverless_Database.sql

# Create the Logins User
cp artifacts/Create_Serveress_SQL_Login_User.sql.tmpl artifacts/Create_Serveress_SQL_Login_User.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Serveress_SQL_Login_User.sql

sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -i artifacts/Create_Serveress_SQL_Login_User.sql

# Restore the firewall rules on ADLS an Azure Synapse Analytics. That was needed temporarily to apply these settings.
if [ "$privateEndpointsEnabled" == "true" ]; then
    echo "Restoring firewall rules..." | tee -a configEnvironment.log
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Deny >> configEnvironment.log 2>&1
    az synapse workspace firewall-rule delete --name AllowAll --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --yes >> configEnvironment.log 2>&1
    az synapse workspace firewall-rule delete --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --yes >> configEnvironment.log 2>&1
fi

###################################################################################################################
#
# Create Service Principal & Key Vault
#     
###################################################################################################################
ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>&1)
KEY_VAULT=${keyVaultName}
ARM_SPN_CREDENTIAL="tpcds-spn-secret"
ARM_SPN_OBJECT="tpcds-spn-object"
ARM_SPN_CLIENT="tpcds-spn-client"
ARM_SPN_TENANT="tpcds-spn-tenant"

STORAGE_ACCT=${datalakeName}
RESOURCE_GROUP=${resourceGroup}
LOCATION=${region}

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

###################################################################################################################
#
# RBAC Roles Assignment
#       
###################################################################################################################
echo "Assign the Resource Group Contributor Role to SPN"
az role assignment create --assignee "$ARM_OBJECT_ID" \
	--role "Contributor" \
	--scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

echo "Assign the Storage Blob Data Contributor Role to SPN"
az role assignment create --assignee "$ARM_OBJECT_ID" \
	--role "Storage Blob Data Contributor" \
	--scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCT"


az keyvault set-policy -n $KEY_VAULT --secret-permissions all --application-id $ARM_CLIENT_ID --object-id $ARM_OBJECT_ID 

echo "Configuration complete!" | tee -a configEnvironment.log
