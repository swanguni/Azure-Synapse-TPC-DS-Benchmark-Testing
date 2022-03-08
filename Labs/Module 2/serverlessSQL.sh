#!/bin/bash
#
# 	  This is the script to laod TPCDS datasets into Serverless SQL.
#
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 2$ bash serverlessSQLIngestion.sh
#

# Get environment details
azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)

# Get the output variables from the Terraform deployment

resourceGroup=$(terraform output -state=../Module 1/Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
synapseAnalyticsWorkspaceName=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
synapseAnalyticsSQLPoolName=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw synapse_sql_pool_name 2>&1)
synapseAnalyticsSQLAdmin=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw synapse_sql_administrator_login 2>&1)
synapseAnalyticsSQLAdminPassword=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw synapse_sql_administrator_login_password 2>&1)
datalakeName=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw datalake_name 2>&1)

datalakeKey=$(terraform output -state=../'Module 1'/Terraform/terraform.tfstate -raw datalake_key 2>&1)
privateEndpointsEnabled=$(terraform output -state=../Module 1/Terraform/terraform.tfstate -raw private_endpoints_enabled 2>&1)

echo "Deployment Type: terraform" | tee -a loadSynapse.log
echo "Azure Subscription: ${azureSubscriptionName}" | tee -a loadSynapse.log
echo "Azure Subscription ID: ${azureSubscriptionID}" | tee -a loadSynapse.log
echo "Azure AD Username: ${azureUsername}" | tee -a loadSynapse.log
echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}" | tee -a loadSynapse.log
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}" | tee -a loadSynapse.log
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}" | tee -a loadSynapse.log
echo "Data Lake Name: ${datalakeName}" | tee -a loadSynapse.log


echo "Creating the TPCDS Demo Data database using Synapse Serverless SQL..." | tee -a loadSynapse.log

# Generate a SAS for the data lake so we can upload some files
tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
destinationStorageSAS=$(az storage container generate-sas --account-name ${datalakeName} --name data --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv)

# Update the variables
cp artifacts/Create_Data_Source_and_File_Formats.sql.tmpl artifacts/Create_Data_Source_and_File_Formats.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Data_Source_and_File_Formats.sql
sed -i "s/REPLACE_SAS/${destinationStorageSAS}/g" artifacts/Create_Data_Source_and_File_Formats.sql


# Create the Data Source and File Format
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:TPCDSDBDemo-ondemand.sql.azuresynapse.net -d "Demo Data (Serverless)" -I -i artifacts/Create_Data_Source_and_File_Formats.sql


# Create the Views over the external data
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:TPCDSDBDemo-ondemand.sql.azuresynapse.net -d "Demo Data (Serverless)" -I -i artifacts/Create_Views.sql

echo "Configuration complete!" | tee -a loadSynapse.log
touch loadServerless.complete