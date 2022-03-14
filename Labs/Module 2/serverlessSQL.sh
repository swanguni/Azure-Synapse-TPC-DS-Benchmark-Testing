#!/bin/bash
################################################################################################
#
# 	  This is the script to laod TPCDS datasets into Serverless SQL.
#
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 2$ bash serverlessSQL.sh
#
################################################################################################

azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)

resourceGroup="PoC-Synapse-Analytics"
synapseAnalyticsWorkspaceName="pocsynapseanalytics-tpcds"
synapseAnalyticsSQLPoolName="DataWarehouse"  
synapseAnalyticsSQLAdmin="sqladminuser"
synapseAnalyticsSQLLoadingUser="LoadingUser"
synapseAnalyticsSQLAdminPassword="Pass@word123"
datalakeContainer1GB="tpcdsacctpoc/data/source_files_001GB_parquet"
datalakeContainer1TB="tpcdsacctpoc/data/source_files_001TB_parquet"

echo "Creating the TPCDS Demo Data database using Synapse Serverless SQL..." | tee -a loadSynapse.log

# Generate a SAS for the data lake so we can upload some files
tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
destinationStorageSAS=$(az storage container generate-sas --account-name ${datalakeName} --name data --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv)

# Update the variables
cp artifacts/Create_Data_Source_and_File_Formats.sql.tmpl artifacts/Create_Data_Source_and_File_Formats.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Data_Source_and_File_Formats.sql
sed -i "s/REPLACE_SAS/${destinationStorageSAS}/g" artifacts/Create_Data_Source_and_File_Formats.sql


# Create the Data Source and File Format
sqlcmd -U ${synapseAnalyticsSQLLoadingUser} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "TPCDSDemo" -I -i artifacts/Create_Data_Source_and_File_Formats.sql


# Create the Views over the external data
cp artifacts/Create_Views.sql.tmpl artifacts/Create_Views.sql 2>&1
sed -i "s/REPLACE_LOCATION/${datalakeContainer1GB}/g" artifacts/Create_Views.sql
sqlcmd -U ${synapseAnalyticsSQLLoadingUser} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "TPCDSDemo" -I -i artifacts/Create_Views.sql

echo "Configuration complete!" | tee -a loadSynapse.log