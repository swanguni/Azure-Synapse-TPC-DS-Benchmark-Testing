#!/bin/bash
#
# 	  This is the script for the Post-Deployment Configuration.
#
#    	  These are post-deployment configurations done at the data plan level which is beyond the scope of what Terraform is 
#       capable of managing or would normally manage, such as Database settings and pipelines.
#
#       This script should be executed via the Azure Cloud Shell via:
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 1$ bash configEnvironment.sh
#

# Get environment details
azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)

# Get the output variables from the Terraform deployment

resourceGroup=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
synapseAnalyticsWorkspaceName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
synapseAnalyticsSQLPoolName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_pool_name 2>&1)
synapseAnalyticsSQLAdmin=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login 2>&1)
synapseAnalyticsSQLAdminPassword=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login_password 2>&1)
datalakeName=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_name 2>&1)

datalakeKey=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_key 2>&1)
privateEndpointsEnabled=$(terraform output -state=Terraform/terraform.tfstate -raw private_endpoints_enabled 2>&1)

echo "Deployment Type: terraform" 
echo "Azure Subscription: ${azureSubscriptionName}" 
echo "Azure Subscription ID: ${azureSubscriptionID}" 
echo "Azure AD Username: ${azureUsername}" 
echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}" 
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}" 
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}" 
echo "Data Lake Name: ${datalakeName}" 

# If Private Endpoints are enabled, temporarily disable the firewalls so we can copy files and perform additional configuration
if [ "$privateEndpointsEnabled" == "true" ]; then
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Allow >> deploySynapse.log 2>&1
    az synapse workspace firewall-rule create --name AllowAll --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255 >> deploySynapse.log 2>&1
    az synapse workspace firewall-rule create --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 >> deploySynapse.log 2>&1
fi

# Enable Result Set Cache
# echo "Enabling Result Set Caching..." | tee -a deploySynapse.log
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET RESULT_SET_CACHING ON;" >> deploySynapse.log 2>&1

# Enable the Query Store
# echo "Enabling the Query Store..." | tee -a deploySynapse.log
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET QUERY_STORE = ON;" >> deploySynapse.log 2>&1

echo "Creating the Auto Pause and Resume pipeline..." | tee -a deploySynapse.log

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

echo "Creating the Parquet Auto TPCDS Ingestion Pipeline..." | tee -a deploySynapse.log

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

# Create the LS_Synapse_Managed_Identity Linked Service. This is primarily used for the Auto Ingestion pipeline.
az synapse linked-service create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name LS_Synapse_Managed_Identity --file @artifacts/LS_Synapse_Managed_Identity.json

# Create the DS_Synapse_Managed_Identity Dataset. This is primarily used for the Auto Ingestion pipeline.
az synapse dataset create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name DS_Synapse_Managed_Identity --file @artifacts/DS_Synapse_Managed_Identity.json

# Copy the Parquet Auto Ingestion Pipeline template and update the variables
cp artifacts/Load_TPC_DS.json.tmpl artifacts/Load_TPC_DS.json 2>&1
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Load_TPC_DS.json

# Create the Parquet Auto Ingestion Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Load TPCDS" --file @artifacts/Load_TPC_DS.json >> deploySynapse.log 2>&1

echo "Creating the TPCDS Demo Data database using Synapse Serverless SQL..." | tee -a deploySynapse.log

# Create a Demo Data database using Synapse Serverless SQL
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -i artifacts/Create_Serverless_Database.sql

sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:TPCDSDBDemo-ondemand.sql.azuresynapse.net -d master -I -Q "CREATE USER LoadingUser FOR LOGIN LoadingUser; ALTER ROLE db_owner ADD MEMBER LoadingUser;CREATE SCHEMA TPCDS;"

sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:TPCDSDBExternal-ondemand.sql.azuresynapse.net -d master -I -Q "CREATE USER LoadingUser FOR LOGIN LoadingUser; ALTER ROLE db_owner ADD MEMBER LoadingUser;CREATE SCHEMA TPCDS;"

# Create the Views over the external data
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "Demo Data (Serverless)" -I -i artifacts/Demo_Data_Serverless_DDL.sql

# Restore the firewall rules on ADLS an Azure Synapse Analytics. That was needed temporarily to apply these settings.
if [ "$privateEndpointsEnabled" == "true" ]; then
    echo "Restoring firewall rules..." | tee -a deploySynapse.log
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Deny >> deploySynapse.log 2>&1
    az synapse workspace firewall-rule delete --name AllowAll --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --yes >> deploySynapse.log 2>&1
    az synapse workspace firewall-rule delete --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --yes >> deploySynapse.log 2>&1
fi

echo "Configuration complete!" | tee -a deploySynapse.log
touch configEnvironment.complete