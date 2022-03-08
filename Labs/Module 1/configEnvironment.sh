#!/bin/bash
#
# 	  This is the script for the Post-Deployment Configuration.
#
#    	  These are post-deployment configurations done at the data plan level which is beyond the scope of what Terraform is 
#       capable of managing or would normally manage, such as Database settings and pipelines.
#
#       This script should be executed via the Azure Cloud Shell via:
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 1$ bash configSynapse.sh
#

# Get the output variables from the Terraform deployment

resourceGroup=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
synapseAnalyticsWorkspaceName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
synapseAnalyticsSQLPoolName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_pool_name 2>&1)
synapseAnalyticsSQLAdmin=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login 2>&1)
synapseAnalyticsSQLAdminPassword=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login_password 2>&1)
datalakeName=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_name 2>&1)

datalakeKey=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_key 2>&1)
privateEndpointsEnabled=$(terraform output -state=Terraform/terraform.tfstate -raw private_endpoints_enabled 2>&1)

echo "Deployment Type: terraform" | tee -a deploySynapse.log
echo "Azure Subscription: ${azureSubscriptionName}" | tee -a deploySynapse.log
echo "Azure Subscription ID: ${azureSubscriptionID}" | tee -a deploySynapse.log
echo "Azure AD Username: ${azureUsername}" | tee -a deploySynapse.log
echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}" | tee -a deploySynapse.log
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}" | tee -a deploySynapse.log
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}" | tee -a deploySynapse.log
echo "Data Lake Name: ${datalakeName}" | tee -a deploySynapse.log

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
#echo "Enabling the Query Store..." | tee -a deploySynapse.log
#sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET QUERY_STORE = ON;" >> deploySynapse.log 2>&1

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
#sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Parquet_Auto_Ingestion.json

# Generate a SAS for the data lake so we can upload some files
#tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
#destinationStorageSAS=$(az storage container generate-sas --account-name ${datalakeName} --name data --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv)

# Update the Parquet Auto Ingestion Metadata file tamplate with the correct storage account and then upload it
#sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Parquet_Auto_Ingestion_Metadata.csv
#azcopy cp 'artifacts/Parquet_Auto_Ingestion_Metadata.csv' 'https://'"${datalakeName}"'.blob.core.windows.net/data?'"${destinationStorageSAS}" >> deploySynapse.log 2>&1


# Copy sample data for the Parquet Auto Ingestion pipeline
# sampleDataStorageSAS="?sv=2020-10-02&st=2021-11-23T05%3A00%3A00Z&se=2022-11-24T05%3A00%3A00Z&sr=c&sp=rl&sig=PMi22pEYzw1dHNrOI9gqrwcbi3AJLq%2BxWoSX9SOTLuw%3D"
# azcopy cp 'https://synapseanalyticspocdata.blob.core.windows.net/sample/AdventureWorks/'"${sampleDataStorageSAS}" 'https://'"${datalakeName}"'.blob.core.windows.net/data/Sample?'"${destinationStorageSAS}" --recursive >> deploySynapse.log 2>&1



# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Load TPCDS" --file @artifacts/Load_TPC_DS.json >> deploySynapse.log 2>&1


# echo "Creating the Demo Data database using Synapse Serverless SQL..." | tee -a deploySynapse.log

# Create a Demo Data database using Synapse Serverless SQL
# sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -Q "CREATE DATABASE [Demo Data (Serverless)];"

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